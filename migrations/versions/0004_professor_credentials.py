"""Optional individual credentials for professor password authentication."""

import sqlalchemy as sa
from alembic import op

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "professor_credentials",
        sa.Column("professor_id", sa.Integer(), primary_key=True),
        sa.Column("username", sa.String(80), nullable=False),
        sa.Column("password_hash", sa.String(256), nullable=False),
        sa.Column("revision", sa.String(64), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["professor_id"], ["professors.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("username", name="uq_professor_credentials_username"),
    )


def downgrade() -> None:
    op.drop_table("professor_credentials")
