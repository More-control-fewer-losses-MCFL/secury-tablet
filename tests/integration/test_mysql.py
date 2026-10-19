"""Regras que dependem do MySQL de verdade: travas, concorrência, índices e JSON."""

from concurrent.futures import ThreadPoolExecutor

import pytest
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError

from armario_tablets.exceptions import AppError, CabinetBusyError, InsufficientAvailabilityError
from armario_tablets.models import CheckoutItem, Event, ItemStatus, Tablet
from tests.factories import (
    ACTIVE_BADGE,
    CABINET_CODE,
    OTHER_ACTIVE_BADGE,
    all_tags,
    seed_basic,
    tag_for,
)

pytestmark = pytest.mark.integration


def test_two_simultaneous_requests_never_both_succeed(db, open_services):
    seed_basic(db, tablets=3)
    outcomes = []

    def attempt(badge):
        _, services = open_services()
        try:
            services.checkout.request_checkout(badge, 2, "Aula", None, CABINET_CODE)
            return "ok"
        except (CabinetBusyError, InsufficientAvailabilityError) as error:
            return type(error).__name__

    with ThreadPoolExecutor(max_workers=2) as pool:
        outcomes = list(pool.map(attempt, [ACTIVE_BADGE, OTHER_ACTIVE_BADGE]))

    assert outcomes.count("ok") == 1
    assert len(db.scalars(select(Event).where(Event.type == "CHECKOUT_REQUESTED")).all()) == 1


def test_same_event_in_parallel_creates_a_single_checkout(db, open_services):
    seed_basic(db, tablets=5)
    _, services = open_services()
    session_id = services.checkout.request_checkout(
        ACTIVE_BADGE, 2, "Aula", None, CABINET_CODE
    ).session_id
    present = all_tags() - {tag_for(1), tag_for(2)}

    def confirm(_):
        _, svc = open_services()
        try:
            return svc.checkout.confirm_checkout(session_id, "evt-parallel-001", present)
        except AppError as error:
            return error

    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(confirm, range(4)))

    assert all(not isinstance(r, Exception) for r in results)
    assert sum(1 for r in results if r.duplicate_event) == 3
    assert len(db.scalars(select(CheckoutItem)).all()) == 2


def test_active_duplicate_is_blocked(db, open_services):
    seed_basic(db)
    _, services = open_services()
    sid = services.checkout.request_checkout(ACTIVE_BADGE, 1, "Aula", None, CABINET_CODE).session_id
    services.checkout.confirm_checkout(sid, "evt-index-00001", all_tags() - {tag_for(1)})

    tablet = db.scalar(select(Tablet).where(Tablet.asset_code == "TAB-001"))
    db.add(CheckoutItem(session_id=sid, tablet_id=tablet.id, status=ItemStatus.ACTIVE))
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_events_details_are_stored_as_json(db, open_services):
    seed_basic(db)
    _, services = open_services()
    sid = services.checkout.request_checkout(ACTIVE_BADGE, 1, "Aula", None, CABINET_CODE).session_id
    services.checkout.confirm_checkout(sid, "evt-json-00001", all_tags() - {tag_for(2)})

    column_type = db.scalar(
        text(
            "SELECT DATA_TYPE FROM information_schema.columns "
            "WHERE table_name = 'events' AND column_name = 'details'"
        )
    )
    taken = db.scalar(
        text(
            "SELECT JSON_UNQUOTE(JSON_EXTRACT(details, '$.taken[0]')) FROM events "
            "WHERE event_id = 'evt-json-00001'"
        )
    )
    assert column_type == "json"
    assert taken == "TAB-002"


def test_expected_indexes_exist(db):
    names = {row[2] for row in db.execute(text("SHOW INDEX FROM checkout_items")).all()}
    assert {"ix_checkout_items_session_id", "ix_checkout_items_tablet_status"}.issubset(names)


def test_history_query_runs_on_mysql(db, open_services):
    seed_basic(db)
    _, services = open_services()
    sid = services.checkout.request_checkout(ACTIVE_BADGE, 2, "Aula", "9A", CABINET_CODE).session_id
    services.checkout.confirm_checkout(
        sid, "evt-hist-mysql-001", all_tags() - {tag_for(1), tag_for(2)}
    )
    page = services.history.page(limit=10)
    assert page.total == 1
    assert (page.rows[0].taken_quantity, page.rows[0].pending_quantity) == (2, 2)
