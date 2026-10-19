"""esquema inicial

Revision ID: 0001
Revises:
Create Date: 2026-10-15 20:16:27.684328
"""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "cabinets",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(length=20), nullable=False),
        sa.Column("door_state", sa.String(length=10), nullable=False),
        sa.Column("lock_state", sa.String(length=10), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_cabinets")),
        sa.UniqueConstraint("code", name=op.f("uq_cabinets_code")),
    )
    op.create_table(
        "professors",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("registration", sa.String(length=30), nullable=False),
        sa.Column("badge_uid", sa.String(length=32), nullable=False),
        sa.Column("active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_professors")),
        sa.UniqueConstraint("badge_uid", name=op.f("uq_professors_badge_uid")),
        sa.UniqueConstraint("registration", name=op.f("uq_professors_registration")),
    )
    op.create_table(
        "tablets",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("asset_code", sa.String(length=40), nullable=False),
        sa.Column("rfid_tag_uid", sa.String(length=32), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "status IN ('AVAILABLE', 'CHECKED_OUT', 'MAINTENANCE')",
            name=op.f("ck_tablets_status_valid"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_tablets")),
        sa.UniqueConstraint("asset_code", name=op.f("uq_tablets_asset_code")),
        sa.UniqueConstraint("rfid_tag_uid", name=op.f("uq_tablets_rfid_tag_uid")),
    )
    op.create_index("ix_tablets_status", "tablets", ["status"], unique=False)
    op.create_table(
        "checkout_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("professor_id", sa.Integer(), nullable=False),
        sa.Column("cabinet_id", sa.Integer(), nullable=False),
        sa.Column("requested_quantity", sa.Integer(), nullable=False),
        sa.Column("purpose", sa.String(length=200), nullable=False),
        sa.Column("class_name", sa.String(length=100), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint(
            "status IN ('PENDING','UNLOCKED','OPEN','DIVERGENT','COMPLETED','CANCELLED','FAILED')",
            name=op.f("ck_checkout_sessions_status_valid"),
        ),
        sa.CheckConstraint(
            "requested_quantity > 0", name=op.f("ck_checkout_sessions_quantity_positive")
        ),
        sa.ForeignKeyConstraint(
            ["cabinet_id"], ["cabinets.id"], name=op.f("fk_checkout_sessions_cabinet_id_cabinets")
        ),
        sa.ForeignKeyConstraint(
            ["professor_id"],
            ["professors.id"],
            name=op.f("fk_checkout_sessions_professor_id_professors"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_checkout_sessions")),
    )
    op.create_index(
        "ix_checkout_sessions_professor_id", "checkout_sessions", ["professor_id"], unique=False
    )
    op.create_index(
        "ix_checkout_sessions_started_at", "checkout_sessions", ["started_at"], unique=False
    )
    op.create_index("ix_checkout_sessions_status", "checkout_sessions", ["status"], unique=False)
    op.create_table(
        "checkout_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=False),
        sa.Column("tablet_id", sa.Integer(), nullable=False),
        sa.Column("checked_out_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("returned_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=10), nullable=False),
        sa.CheckConstraint(
            "status IN ('ACTIVE', 'RETURNED')", name=op.f("ck_checkout_items_status_valid")
        ),
        sa.ForeignKeyConstraint(
            ["session_id"],
            ["checkout_sessions.id"],
            name=op.f("fk_checkout_items_session_id_checkout_sessions"),
        ),
        sa.ForeignKeyConstraint(
            ["tablet_id"], ["tablets.id"], name=op.f("fk_checkout_items_tablet_id_tablets")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_checkout_items")),
    )
    op.create_index("ix_checkout_items_session_id", "checkout_items", ["session_id"], unique=False)
    op.create_index("ix_checkout_items_tablet_status", "checkout_items", ["tablet_id", "status"], unique=False)
    op.create_table(
        "events",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("event_id", sa.String(length=64), nullable=False),
        sa.Column("cabinet_id", sa.Integer(), nullable=False),
        sa.Column("session_id", sa.Integer(), nullable=True),
        sa.Column("type", sa.String(length=40), nullable=False),
        sa.Column("source", sa.String(length=30), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("details", sa.JSON(), nullable=False),
        sa.ForeignKeyConstraint(
            ["cabinet_id"], ["cabinets.id"], name=op.f("fk_events_cabinet_id_cabinets")
        ),
        sa.ForeignKeyConstraint(
            ["session_id"],
            ["checkout_sessions.id"],
            name=op.f("fk_events_session_id_checkout_sessions"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_events")),
        sa.UniqueConstraint("event_id", name=op.f("uq_events_event_id")),
    )
    op.create_index("ix_events_occurred_at", "events", ["occurred_at"], unique=False)
    op.create_index("ix_events_session_id", "events", ["session_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_events_session_id", table_name="events")
    op.drop_index("ix_events_occurred_at", table_name="events")
    op.drop_table("events")
    op.drop_index("ix_checkout_items_tablet_status", table_name="checkout_items")
    op.drop_index("ix_checkout_items_session_id", table_name="checkout_items")
    op.drop_table("checkout_items")
    op.drop_index("ix_checkout_sessions_status", table_name="checkout_sessions")
    op.drop_index("ix_checkout_sessions_started_at", table_name="checkout_sessions")
    op.drop_index("ix_checkout_sessions_professor_id", table_name="checkout_sessions")
    op.drop_table("checkout_sessions")
    op.drop_index("ix_tablets_status", table_name="tablets")
    op.drop_table("tablets")
    op.drop_table("professors")
    op.drop_table("cabinets")
