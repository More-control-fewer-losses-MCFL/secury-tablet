"""Opt-in Docker regressions; isolated resources and fictional credentials only."""

import json
import os
import subprocess
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
IMAGE = os.environ.get("WEB_PROXY_TEST_IMAGE")
pytestmark = pytest.mark.skipif(
    not IMAGE, reason="set WEB_PROXY_TEST_IMAGE for isolated Docker tests"
)


def docker(*args, check=True):
    result = subprocess.run(["docker", *args], capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError(f"Docker fixture failed: {result.stderr[:1500]}")
    return (result.stdout + (result.stderr if args[0] == "logs" else "")).strip()


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *_args, **_kwargs):
        return None


def request(base, path, body=None, headers=None, timeout=8):
    payload = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(base + path, data=payload, headers=headers or {})
    if payload is not None:
        req.add_header("Content-Type", "application/json")
    try:
        response = urllib.request.build_opener(NoRedirect).open(req, timeout=timeout)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        return response.status, response.headers, response.read()


def wait_for(base, path="/healthz", timeout=30):
    # Poll only fixture readiness, never a failed business operation.
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if request(base, path)[0] == 200:
                return
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(0.25)
    raise AssertionError("isolated fixture did not become ready")


class Sandbox:
    def __init__(self, network):
        self.network = network
        self.containers = []

    def run(self, image, *, env=None, alias=None, command=(), mounts=()):
        name = "secury-proxy-" + uuid.uuid4().hex[:10]
        self.containers.append(name)
        args = ["run", "-d", "--name", name, "--network", self.network]
        if alias:
            args += ["--network-alias", alias]
        if image == IMAGE:
            args += ["-p", "127.0.0.1::80"]
        for key, value in (env or {}).items():
            args += ["-e", f"{key}={value}"]
        for mount in mounts:
            args += ["--mount", mount]
        docker(*args, image, *command)
        return name

    def web(self, **env):
        name = self.run(IMAGE, env=env)
        base = "http://" + docker("port", name, "80/tcp").splitlines()[0]
        wait_for(base)
        return name, base

    def stub(self, alias="api", **env):
        return self.run(
            "python:3.12-slim",
            env=env,
            alias=alias,
            command=("python", "-u", "/fixture.py"),
            mounts=(
                f"type=bind,source={ROOT / 'tests/docker/upstream_fixture.py'},"
                "target=/fixture.py,readonly",
            ),
        )


@pytest.fixture
def sandbox():
    network = "secury-proxy-" + uuid.uuid4().hex[:10]
    docker("network", "create", "--ipv6", network)
    fixture = Sandbox(network)
    try:
        yield fixture
    finally:
        for name in reversed(fixture.containers):
            docker("rm", "-f", name, check=False)
        docker("network", "rm", network, check=False)


def test_generated_config_and_private_runtime_override(sandbox):
    sandbox.stub(alias="fixture.railway.internal", STUB_PORT="8001")
    name, base = sandbox.web(
        API_UPSTREAM_HOST="fixture.railway.internal",
        API_UPSTREAM_PORT="8001",
        host="wrong",
        uri="wrong",
        NGINX_ENVSUBST_FILTER=".*",
    )
    output = docker("exec", name, "nginx", "-T")
    for variable in ["$host", "$http_host", "$scheme", "$uri", "$binary_remote_addr"]:
        assert variable in output
    assert "fixture.railway.internal:8001" in output
    assert "ipv6=off" not in output
    assert "${API_UPSTREAM" not in output
    docker("exec", name, "nginx", "-t")
    assert request(base, "/api/health")[0] == 200
    assert not docker(
        "exec",
        name,
        "sh",
        "-c",
        "grep -l fixture.railway.internal /usr/share/nginx/html/main.dart.js || true",
    )


@pytest.mark.parametrize(
    "env",
    [
        {"API_UPSTREAM_HOST": ""},
        {"API_UPSTREAM_HOST": "https://api"},
        {"API_UPSTREAM_HOST": "api;injected"},
        {"API_UPSTREAM_HOST": "api\nother"},
        {"API_UPSTREAM_HOST": "-api"},
        {"API_UPSTREAM_HOST": "api..internal"},
        {"API_UPSTREAM_PORT": "0"},
        {"API_UPSTREAM_PORT": "65536"},
        {"API_UPSTREAM_PORT": "eight"},
        {"API_UPSTREAM_PORT": "08000"},
        {"NGINX_ENTRYPOINT_LOCAL_RESOLVERS": "", "NGINX_LOCAL_RESOLVERS": ""},
    ],
)
def test_invalid_runtime_fails_before_serving(sandbox, env):
    name = sandbox.run(IMAGE, env=env)
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if docker("inspect", "-f", "{{.State.Running}}", name) == "false":
            break
        time.sleep(0.1)
    assert docker("inspect", "-f", "{{.State.ExitCode}}", name) != "0"
    assert "Invalid Nginx runtime configuration:" in docker("logs", name, check=False)


def test_paths_queries_headers_cookies_and_statuses(sandbox):
    sandbox.stub()
    _, base = sandbox.web()
    for route in ["/admin/login", "/auth/professor/login", "/auth/rfid", "/echo"]:
        status, headers, body = request(
            base,
            "/api" + route + "?term=a%20b&limit=2",
            body={"fixture": "payload"},
            headers={
                "Authorization": "Bearer fictional-token",
                "Cookie": "fixture=not-a-secret",
                "Host": "public.fixture:8123",
                "X-Forwarded-Proto": "https",
            },
        )
        assert status == 200
        value = json.loads(body)
        assert value["path"] == route + "?term=a%20b&limit=2"
        assert value["method"] == "POST" and json.loads(value["body"]) == {"fixture": "payload"}
        received = {k.lower(): v for k, v in value["headers"].items()}
        assert received["host"] == received["x-forwarded-host"] == "public.fixture:8123"
        assert received["x-forwarded-proto"] == "https"
        assert received["authorization"] == "Bearer fictional-token"
        assert received["cookie"] == "fixture=not-a-secret"
        assert all(
            flag in headers["Set-Cookie"] for flag in ["HttpOnly", "Secure", "SameSite=Strict"]
        )
    for status in [401, 403, 404, 502, 503, 504]:
        assert request(base, f"/api/status/{status}")[0] == status
    _, _, body = request(base, "/api/echo", headers={"X-Forwarded-Proto": "https,evil"})
    assert json.loads(body)["headers"]["X-Forwarded-Proto"] == "http"


@pytest.mark.parametrize(
    "route,count", [("/admin/login", 9), ("/auth/professor/login", 9), ("/auth/rfid", 15)]
)
def test_authentication_rate_limits_remain_active(sandbox, route, count):
    sandbox.stub()
    _, base = sandbox.web()
    statuses = [request(base, "/api" + route, body={"fixture": True})[0] for _ in range(count)]
    assert 200 in statuses and 429 in statuses


def test_ipv6_only_upstream_and_backend_unavailable(sandbox):
    stub = sandbox.stub(alias="ipv6-api", IPV6_ONLY="true")
    name, base = sandbox.web(API_UPSTREAM_HOST="ipv6-api")
    wait_for(base, "/api/health")
    docker("stop", stub)
    started = time.monotonic()
    # A dead cached address may refuse TCP (502) or time out connecting (504).
    assert request(base, "/api/health")[0] in {502, 504}
    assert time.monotonic() - started < 8
    assert request(base, "/healthz")[0] == 200
    assert docker("inspect", "-f", "{{.State.Running}}", name) == "true"


def test_dns_failure_and_re_resolution_without_nginx_restart(sandbox):
    old = sandbox.stub()
    name, base = sandbox.web()
    wait_for(base, "/api/health")
    identity = docker("inspect", "-f", "{{.Id}}", name)
    new = sandbox.stub(GENERATION="second")
    docker("network", "disconnect", sandbox.network, old)
    # New container starts while the old address is occupied, forcing a different IP.
    deadline = time.monotonic() + 25
    resolved = False
    while time.monotonic() < deadline:
        status, _, body = request(base, "/api/health")
        if status == 200 and json.loads(body)["generation"] == "second":
            resolved = True
            break
        time.sleep(1)
    assert resolved and new != old
    assert docker("inspect", "-f", "{{.Id}}", name) == identity
    _, missing = sandbox.web(API_UPSTREAM_HOST="absent-fixture.internal")
    assert request(missing, "/api/health")[0] == 502


def test_slow_upstream_exceeds_the_unchanged_client_deadline(sandbox):
    sandbox.stub()
    _, base = sandbox.web()
    started = time.monotonic()
    with pytest.raises((TimeoutError, urllib.error.URLError)):
        request(base, "/api/slow", timeout=12)
    assert 11 <= time.monotonic() - started < 15
    assert request(base, "/healthz")[0] == 200


def test_ipv6_nameserver_is_rendered_without_disabling_ipv6(sandbox):
    name, base = sandbox.web(
        NGINX_ENTRYPOINT_LOCAL_RESOLVERS="",
        NGINX_LOCAL_RESOLVERS="[fd00::53] 127.0.0.11",
    )
    output = docker("exec", name, "nginx", "-T")
    assert "resolver [fd00::53] 127.0.0.11 valid=10s;" in output
    assert "ipv6=off" not in output
    assert request(base, "/healthz")[0] == 200
