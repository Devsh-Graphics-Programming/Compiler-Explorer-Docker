# -*- coding: utf-8 -*-
import argparse
import time
import urllib.request
import sys


def check_health(url):
    """
    Check the health of the server by making a HEAD request to the provided URL.
    :param url: URL to check health (e.g., http://localhost:10240)
    :return: True if the server responds with status code 200, False otherwise.
    """
    try:
        request = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(request, timeout=5) as response:
            return response.status == 200
    except Exception as e:
        print(f"[ERROR] Exception thrown during health check: {e}", file=sys.stderr, flush=True)
        return False


def run_health_checks(url, interval, ticks):
    """
    Run health checks on a server for a specified number of attempts.
    :param url: URL to check health (e.g., http://localhost:10240)
    :param interval: Time interval between checks (in seconds)
    :param ticks: Number of health check attempts
    :return: 0 if successful, 1 if all attempts fail.
    """
    for attempt in range(1, ticks + 1):
        print(f"[INFO] Attempt {attempt} of {ticks}: Checking health...", flush=True)
        if check_health(url):
            print(f"[SUCCESS] Health check succeeded on attempt {attempt}.", flush=True)
            return 0
        else:
            print(f"[ERROR] Health check failed on attempt {attempt}. Retrying in {interval} seconds...", flush=True)
            time.sleep(interval)

    print(f"[ERROR] Server did not become healthy after {ticks} attempts.", file=sys.stderr, flush=True)
    return 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run health checks for a server.")
    parser.add_argument(
        "--url",
        type=str,
        default="http://localhost:10240",
        help="The URL to check health (default: http://localhost:10240).",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=5,
        help="Interval between health checks (in seconds). Default is 5.",
    )
    parser.add_argument(
        "--ticks",
        type=int,
        default=15,
        help="Number of health check attempts. Default is 15.",
    )

    args = parser.parse_args()
    sys.exit(run_health_checks(args.url, args.interval, args.ticks))
