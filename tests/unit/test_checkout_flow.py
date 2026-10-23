from datetime import timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from armario_tablets.exceptions import (
    CabinetBusyError,
    InsufficientAvailabilityError,
    InvalidSessionStateError,
    LockError,
    ProfessorInactiveError,
    ProfessorNotFoundError,
    ReaderError,
)
from armario_tablets.models import (
    CheckoutItem,
    CheckoutSession,
    Event,
    ItemStatus,
    SessionStatus,
    Tablet,
    TabletStatus,
)
from armario_tablets.utils.datetime_utils import utcnow
from tests.factories import ACTIVE_BADGE, CABINET_CODE, INACTIVE_BADGE, all_tags, tag_for


def request(services, quantity=2, badge=ACTIVE_BADGE):
    return services.checkout.request_checkout(
        badge, quantity, "Aula de pesquisa", "9A - Ciências", CABINET_CODE
    )


def event_types(db, session_id):
    return [e.type for e in db.scalars(select(Event).where(Event.session_id == session_id))]


def tablet_status(db, number):
    return db.scalar(select(Tablet.status).where(Tablet.rfid_tag_uid == tag_for(number)))


# ---------- Professor ativo / inativo ----------


def test_active_professor_is_identified(services):
    assert services.badges.identify(" de-00-00-01 ").name == "Ana Teste"


def test_inactive_professor_is_rejected(services):
    with pytest.raises(ProfessorInactiveError):
        services.badges.identify(INACTIVE_BADGE)


def test_unknown_badge_is_rejected(services):
    with pytest.raises(ProfessorNotFoundError):
        services.badges.identify("DEADBEEF")


def test_inactive_professor_cannot_request(services, db):
    with pytest.raises(ProfessorInactiveError):
        request(services, badge=INACTIVE_BADGE)
    assert db.scalars(select(CheckoutSession)).all() == []


# ---------- Disponibilidade ----------


def test_request_above_availability_is_rejected(services, db):
    with pytest.raises(InsufficientAvailabilityError):
        request(services, quantity=6)
    assert db.scalars(select(CheckoutSession)).all() == []


def test_request_unlocks_but_does_not_mark_tablets_as_taken(services, db):
    result = request(services, quantity=2)
    assert result.status == SessionStatus.UNLOCKED
    assert result.taken_quantity == 0  # a quantidade pedida NÃO é a quantidade retirada
    assert services.availability.available_count() == 5


def test_second_request_while_cabinet_is_busy_is_rejected(services):
    request(services, quantity=1)
    with pytest.raises(CabinetBusyError):
        request(services, quantity=1)


def test_stale_reservation_expires(services, db):
    first = request(services, quantity=1)
    old = db.get(CheckoutSession, first.session_id)
    old.started_at = utcnow() - timedelta(minutes=30)
    db.commit()
    second = request(services, quantity=1)
    assert db.get(CheckoutSession, first.session_id).status == SessionStatus.CANCELLED
    assert second.status == SessionStatus.UNLOCKED


# ---------- Retirada ----------


def test_checkout_confirms_only_tablets_whose_tags_disappeared(services, db):
    session = request(services, quantity=2)
    present = all_tags() - {tag_for(1), tag_for(2)}
    result = services.checkout.confirm_checkout(session.session_id, "evt-checkout-001", present)

    assert result.status == SessionStatus.OPEN
    assert sorted(i.asset_code for i in result.items) == ["TAB-001", "TAB-002"]
    assert result.divergence is None
    assert tablet_status(db, 1) == TabletStatus.CHECKED_OUT
    assert tablet_status(db, 3) == TabletStatus.AVAILABLE
    assert services.availability.available_count() == 3


def test_partial_reading_records_only_confirmed_tablets(services, db):
    session = request(services, quantity=3)
    present = all_tags() - {tag_for(1), tag_for(2)}  # só 2 identificados dos 3 pedidos
    result = services.checkout.confirm_checkout(session.session_id, "evt-partial-001", present)

    assert result.taken_quantity == 2
    assert result.requested_quantity == 3
    assert "parcial" in result.divergence.lower()
    assert "PARTIAL_WITHDRAWAL" in event_types(db, session.session_id)


def test_taking_more_than_requested_is_recorded_as_divergence(services, db):
    session = request(services, quantity=1)
    present = all_tags() - {tag_for(1), tag_for(2)}
    result = services.checkout.confirm_checkout(session.session_id, "evt-extra-0001", present)
    assert result.taken_quantity == 2
    assert "EXTRA_WITHDRAWAL" in event_types(db, session.session_id)


def test_nothing_taken_cancels_the_request(services, db):
    session = request(services, quantity=2)
    result = services.checkout.confirm_checkout(session.session_id, "evt-none-00001", all_tags())
    assert result.status == SessionStatus.CANCELLED
    assert services.availability.available_count() == 5


def test_confirm_requires_unlocked_state(services):
    session = request(services, quantity=1)
    services.checkout.confirm_checkout(
        session.session_id, "evt-first-0001", all_tags() - {tag_for(1)}
    )
    with pytest.raises(InvalidSessionStateError):
        services.checkout.confirm_checkout(session.session_id, "evt-second-001", all_tags())


def test_tablet_already_checked_out_is_not_offered_again(services, db):
    first = request(services, quantity=2)
    services.checkout.confirm_checkout(
        first.session_id, "evt-a-0000001", all_tags() - {tag_for(1), tag_for(2)}
    )
    with pytest.raises(InsufficientAvailabilityError):
        request(services, quantity=4)  # só 3 restam no armário
    second = request(services, quantity=3, badge="DE000002")
    # TAB-001/002 continuam fora: mesmo "aparecendo" ausentes, não viram retirada nova.
    result = services.checkout.confirm_checkout(
        second.session_id, "evt-b-0000001", {tag_for(1), tag_for(2)}
    )
    assert sorted(i.asset_code for i in result.items) == ["TAB-003", "TAB-004", "TAB-005"]


def test_database_blocks_two_active_checkouts_of_same_tablet(services, db):
    session = request(services, quantity=1)
    services.checkout.confirm_checkout(
        session.session_id, "evt-db-0000001", all_tags() - {tag_for(1)}
    )
    tablet = db.scalar(select(Tablet).where(Tablet.asset_code == "TAB-001"))
    db.add(
        CheckoutItem(session_id=session.session_id, tablet_id=tablet.id, status=ItemStatus.ACTIVE)
    )
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


# ---------- Idempotência ----------


def test_repeated_event_does_not_create_second_checkout(services, db):
    session = request(services, quantity=2)
    present = all_tags() - {tag_for(1), tag_for(2)}
    first = services.checkout.confirm_checkout(session.session_id, "evt-dup-000001", present)
    again = services.checkout.confirm_checkout(session.session_id, "evt-dup-000001", present)

    assert first.duplicate_event is False
    assert again.duplicate_event is True
    assert again.taken_quantity == 2
    assert len(db.scalars(select(CheckoutItem)).all()) == 2


# ---------- Erros de fechadura / leitor ----------


def test_lock_command_failure_marks_session_failed(services, hardware, db):
    hardware.lock_controller.fail_on_send = True
    with pytest.raises(LockError):
        request(services)
    session = db.scalar(select(CheckoutSession))
    assert session.status == SessionStatus.FAILED
    assert "LOCK_ERROR" in event_types(db, session.id)
    assert services.availability.available_count() == 5


def test_command_without_physical_confirmation_times_out(services, hardware, db):
    hardware.lock_controller.never_confirms = True  # comando enviado, sensor não confirma
    with pytest.raises(LockError):
        request(services)
    assert db.scalar(select(CheckoutSession)).status == SessionStatus.FAILED


def test_reader_failure_keeps_tablets_untouched_and_logs_error(services, hardware, db):
    session = request(services, quantity=1)
    hardware.tablet_reader.fail = True
    with pytest.raises(ReaderError):
        services.checkout.confirm_checkout(session.session_id, "evt-reader-0001")
    assert db.get(CheckoutSession, session.session_id).status == SessionStatus.UNLOCKED
    assert services.availability.available_count() == 5
    assert "READER_ERROR" in event_types(db, session.session_id)


def test_inventory_can_be_read_from_the_reader(services, hardware):
    session = request(services, quantity=1)
    hardware.tablet_reader.present_tags = all_tags() - {tag_for(4)}
    result = services.checkout.confirm_checkout(session.session_id, "evt-reader-ok-01")
    assert [i.asset_code for i in result.items] == ["TAB-004"]
