import pytest
import asyncio
from backend.services.technitium_dns_service import (
    TechnitiumDnsService,
    validate_and_normalize_domain,
    is_subdomain_match
)


def test_domain_validation_valid():
    valid_domains = [
        "example.com",
        "www.example.com",
        "login.secure-bank.co.uk",
        "sub.domain.test.org"
    ]
    for d in valid_domains:
        is_valid, clean, err = validate_and_normalize_domain(d)
        assert is_valid is True, f"Expected {d} to be valid, got error: {err}"
        assert clean == d.lower()


def test_domain_validation_invalid():
    invalid_inputs = [
        "",
        "   ",
        "127.0.0.1",
        "192.168.1.1",
        "http://invalid_domain_name!!",
        "example..com",
        "domain with spaces.com",
        "-invalidstart.com"
    ]
    for d in invalid_inputs:
        is_valid, clean, err = validate_and_normalize_domain(d)
        assert is_valid is False, f"Expected {d} to be invalid"
        assert err is not None


def test_subdomain_label_boundary_matching():
    # Matches
    assert is_subdomain_match("example.com", "example.com") is True
    assert is_subdomain_match("example.com", "www.example.com") is True
    assert is_subdomain_match("example.com", "login.example.com") is True

    # Should NOT match
    assert is_subdomain_match("example.com", "example.com.evil.com") is False
    assert is_subdomain_match("example.com", "myexample.com") is False
    assert is_subdomain_match("example.com", "notexample.com") is False


@pytest.mark.asyncio
async def test_technitium_service_status():
    service = TechnitiumDnsService()
    status_info = await service.get_server_status()
    assert "status" in status_info
    assert status_info["status"] in ["ONLINE", "OFFLINE", "TIMEOUT", "ERROR"]


if __name__ == "__main__":
    print("Running domain validation and label matching unit tests...")
    test_domain_validation_valid()
    test_domain_validation_invalid()
    test_subdomain_label_boundary_matching()
    print("ALL UNIT TESTS PASSED SUCCESSFULLY!")
