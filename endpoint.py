# -*- coding: utf-8 -*-
import argparse
import urllib.request
import json
import sys
import os
import http.cookiejar


def request(base_url, endpoint, method="GET", data=None, timeout=5, disable_cookies=False):
    """
    Perform a raw API request (GET/POST), optionally without sending cookies.
    :param base_url: The base URL of the server.
    :param endpoint: API endpoint (e.g., "/api/compiler/<ID>/compile").
    :param method: HTTP method ("GET" or "POST").
    :param data: Data to send in a POST request (dict or None).
    :param timeout: Timeout duration for the request (in seconds).
    :param disable_cookies: If True, disables sending cookies.
    :return: Parsed JSON response if successful, None otherwise.
    """
    url = f"{base_url}{endpoint}"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    try:
        json_data = json.dumps(data).encode("utf-8") if data else None
        req = urllib.request.Request(url, data=json_data, method=method, headers=headers)

        if disable_cookies:
            opener = urllib.request.build_opener()
        else:
            cookiejar = http.cookiejar.CookieJar()
            opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookiejar))

        with opener.open(req, timeout=timeout) as response:
            raw_response = response.read().decode("utf-8").strip()

            if not raw_response:
                print("[ERROR] Empty response received.", file=sys.stderr, flush=True)
                return None

            return json.loads(raw_response)

    except Exception as e:
        print(f"[ERROR] Exception thrown during {method} request to {endpoint}: {e}", file=sys.stderr, flush=True)
        return None


def load_json_file(json_path):
    """
    Load a JSON payload from a file.
    :param json_path: Path to the JSON file.
    :return: Parsed JSON dictionary.
    """
    if not os.path.exists(json_path):
        print(f"[ERROR] JSON file not found: {json_path}", file=sys.stderr, flush=True)
        sys.exit(-1)

    try:
        with open(json_path, "r", encoding="utf-8") as file:
            return json.load(file)
    except json.JSONDecodeError as e:
        print(f"[ERROR] Failed to parse JSON file: {e}", file=sys.stderr, flush=True)
        sys.exit(-1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Raw API requester for Compiler Explorer.")
    parser.add_argument(
        "--url",
        type=str,
        default="http://localhost:80",
        help="Base URL of the Compiler Explorer instance (default: http://localhost:80)."
    )
    parser.add_argument(
        "--endpoint",
        type=str,
        required=True,
        help="API endpoint to query (e.g., /api/compiler/nsc_debug_upstream/compile)."
    )
    parser.add_argument(
        "--method",
        type=str,
        choices=["GET", "POST"],
        default="GET",
        help="HTTP method to use (GET or POST). Default is GET."
    )
    parser.add_argument(
        "--data",
        type=str,
        default=None,
        help="JSON data for POST requests (as a string)."
    )
    parser.add_argument(
        "--json",
        type=str,
        default=None,
        help="Path to a JSON file for POST request payload."
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=5,
        help="Request timeout in seconds (default: 5)."
    )
    parser.add_argument(
        "--disable-cookies",
        action="store_true",
        help="Disable sending cookies with the request."
    )

    args = parser.parse_args()

    if args.json:
        json_data = load_json_file(args.json)
    else:
        json_data = json.loads(args.data) if args.data else None

    result = request(args.url, args.endpoint, args.method, json_data, args.timeout, args.disable_cookies)

    if result:
        print(json.dumps(result, indent=2))
        sys.exit(0)
    else:
        print("[ERROR] Request failed.", file=sys.stderr, flush=True)
        sys.exit(-1)