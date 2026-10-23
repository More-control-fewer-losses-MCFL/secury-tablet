"""adiciona coluna active_tablet_id e restricao uq_checkout_items_active_tablet

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-19 19:45:00.000000
"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "checkout_items",
        sa.Column(
            "active_tablet_id",
            sa.Integer(),
            sa.Computed(
                "CASE WHEN status = 'ACTIVE' THEN tablet_id ELSE NULL END",
                persisted=False,
            ),
            nullable=True,
        ),
    )
    op.create_unique_constraint(
        op.f("uq_checkout_items_active_tablet"),
        "checkout_items",
        ["active_tablet_id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("uq_checkout_items_active_tablet"),
        "checkout_items",
        type_="unique",
    )
    op.drop_column("checkout_items", "active_tablet_id")
