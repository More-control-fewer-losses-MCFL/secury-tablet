import pytest
from sqlalchemy import select

from armario_tablets.exceptions import InvalidSessionStateError
from armario_tablets.models import Event, SessionStatus, Tablet, TabletStatus
from tests.factories import ACTIVE_BADGE, CABINET_CODE, all_tags, tag_for


@pytest.fixture
def open_session(services):
    """Professor retirou TAB-001, TAB-002 e TAB-003."""
    session = services.checkout.request_checkout(ACTIVE_BADGE, 3, "Projeto", None, CABINET_CODE)
    taken = {tag_for(1), tag_for(2), tag_for(3)}
    services.checkout.confirm_checkout(session.session_id, "evt-out-0000001", all_tags() - taken)
    return session.session_id


def test_complete_return_closes_the_session(services, db, open_session):
    result = services.returns.reconcile(open_session, "evt-ret-0000001", all_tags())

    assert result.status == SessionStatus.COMPLETED
    assert result.pending_quantity == 0
    assert result.divergence is None
    assert services.availability.available_count() == 5
    assert all(i.returned_at is not None for i in result.items)


def test_dashboard_counts_tablets_moved_today(services, open_session):
    assert services.history.dashboard()["withdrawn_today"] == 3

    services.returns.reconcile(open_session, "evt-ret-dash-0001", all_tags())

    dashboard = services.history.dashboard()
    assert dashboard["withdrawn_today"] == 3
    assert dashboard["returned_today"] == 3


def test_incomplete_return_leaves_pending_items_and_divergence(services, db, open_session):
    present = all_tags() - {tag_for(3)}  # TAB-003 não voltou
    result = services.returns.reconcile(open_session, "evt-ret-0000002", present)

    assert result.status == SessionStatus.DIVERGENT
    assert result.pending_quantity == 1
    assert "TAB-003" in result.divergence
    assert db.scalar(select(Tablet.status).where(Tablet.asset_code == "TAB-003")) == (
        TabletStatus.CHECKED_OUT
    )
    types = [e.type for e in db.scalars(select(Event).where(Event.session_id == open_session))]
    assert "RETURN_DIVERGENCE" in types


def test_pending_item_can_be_returned_later(services, open_session):
    services.returns.reconcile(open_session, "evt-ret-0000003", all_tags() - {tag_for(3)})
    result = services.returns.reconcile(open_session, "evt-ret-0000004", all_tags())
    assert result.status == SessionStatus.COMPLETED
    assert result.pending_quantity == 0


def test_repeated_return_event_is_ignored(services, open_session):
    services.returns.reconcile(open_session, "evt-ret-0000005", all_tags())
    again = services.returns.reconcile(open_session, "evt-ret-0000005", all_tags())
    assert again.duplicate_event is True
    assert again.status == SessionStatus.COMPLETED


def test_return_of_closed_session_is_rejected(services, open_session):
    services.returns.reconcile(open_session, "evt-ret-0000006", all_tags())
    with pytest.raises(InvalidSessionStateError):
        services.returns.reconcile(open_session, "evt-ret-0000007", all_tags())


def test_unknown_tag_does_not_break_reconciliation(services, open_session):
    result = services.returns.reconcile(open_session, "evt-ret-0000008", all_tags() | {"FFFFFFFF"})
    assert result.status == SessionStatus.COMPLETED
