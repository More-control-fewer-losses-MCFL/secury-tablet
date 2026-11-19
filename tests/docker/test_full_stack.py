"""Real FastAPI/MySQL behind the built proxy, in an explicitly disposable Compose project."""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest
from tests.docker.test_web_proxy import request

ROOT = Path(__file__).resolve().parents[2]
PROJECT = os.environ.get("PROXY_STACK_PROJECT", "")
pytestmark = pytest.mark.skipif(
    not PROJECT, reason="set PROXY_STACK_PROJECT for disposable stack tests"
)
ADMIN_PASSWORD = "fictional-administrator-password"
TEACHER_PASSWORD = "fictional-proxy-professor-password"


def compose(*args):
    assert PROJECT.startswith("secury-proxy-review-")
    result = subprocess.run(
        [
            "docker",
            "compose",
            "--env-file",
            os.devnull,
            "-p",
            PROJECT,
            "-f",
            str(ROOT / "tests/docker/compose.proxy-test.yml"),
            *args,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


@pytest.fixture(scope="module")
def stack():
    base = "http://" + compose("port", "web", "80").splitlines()[0]
    status, _, data = request(
        base, "/api/admin/login", {"username": "admin", "password": ADMIN_PASSWORD}
    )
    assert status == 200
    admin = {"Authorization": "Bearer " + json.loads(data)["access_token"]}
    # All operations target the new tmpfs test database, not an existing cabinet.
    compose("exec", "-T", "api", "python", "scripts/seed_demo.py")
    status, _, data = request(base, "/api/professors/by-badge/DE000001", headers=admin)
    assert status == 200
    professor_id = json.loads(data)["id"]
    assert (
        request(
            base,
            f"/api/admin/professors/{professor_id}/credentials",
            {"username": "teacher.fixture", "password": TEACHER_PASSWORD},
            headers=admin,
        )[0]
        == 200
    )
    status, _, data = request(
        base,
        "/api/auth/professor/login",
        {"username": "teacher.fixture", "password": TEACHER_PASSWORD},
    )
    assert status == 200
    teacher = {"Authorization": "Bearer " + json.loads(data)["access_token"]}
    return base, admin, teacher


def test_page_health_and_root_path(stack):
    base, _, _ = stack
    assert request(base, "/")[0] == 200
    assert request(base, "/healthz")[0] == 200
    assert json.loads(request(base, "/api/health")[2]) == {"status": "ok", "database": "ok"}
    status, _, data = request(base, "/api/openapi.json")
    assert status == 200 and {"url": "/api"} in json.loads(data)["servers"]
    status, headers, _ = request(
        base,
        "/api/health/",
        headers={
            "Host": "public.fixture:8123",
            "X-Forwarded-Proto": "https",
        },
    )
    assert status == 307 and headers["Location"] == "https://public.fixture:8123/api/health"


def test_sessions_and_authorization(stack):
    base, admin, teacher = stack
    assert request(base, "/api/admin/session", headers=admin)[0] == 200
    assert request(base, "/api/auth/professor/session", headers=teacher)[0] == 200
    assert request(base, "/api/admin/session")[0] == 401
    assert request(base, "/api/tablets", headers=teacher)[0] == 403
    assert request(base, "/api/nonexistent-fixture", headers=admin)[0] == 404


def test_terminal_cookie_round_trip(stack):
    base, admin, _ = stack
    status, headers, _ = request(base, "/api/terminal/authorize", {}, headers=admin)
    assert status == 200
    cookie = headers["Set-Cookie"]
    assert all(flag in cookie for flag in ["HttpOnly", "Secure", "SameSite=strict"])
    assert request(base, "/api/auth/rfid", {"badge_uid": "DE000001"})[0] == 401
    assert (
        request(
            base,
            "/api/auth/rfid",
            {"badge_uid": "DE000001"},
            headers={"Cookie": cookie.split(";", 1)[0]},
        )[0]
        == 200
    )


def test_existing_mysql_integration_suite_uses_separate_test_database(stack):
    sql = (
        "CREATE DATABASE secury_integration_test;"
        "GRANT ALL ON secury_integration_test.* TO 'proxy_test'@'%';"
    )
    compose(
        "exec",
        "-T",
        "db",
        "sh",
        "-c",
        'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "$1"',
        "sh",
        sql,
    )
    port = compose("port", "db", "3306").splitlines()[0].rsplit(":", 1)[1]
    url = (
        "mysql+pymysql://proxy_test:fictional-proxy-test-password"
        f"@127.0.0.1:{port}/secury_integration_test"
    )
    env = {**os.environ, "TEST_DATABASE_URL": url}
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "tests/integration", "-q"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    print(result.stdout[-1200:])
    assert result.returncode == 0


def test_database_unavailable_is_503_and_frontend_stays_alive(stack):
    base, _, _ = stack
    compose("stop", "db")
    try:
        assert request(base, "/api/health", timeout=15)[0] == 503
        assert request(base, "/healthz")[0] == 200
    finally:
        compose("start", "db")
