#!/usr/bin/env python
import requests

def main():
    print("Hello from package-c!")
    print(requests.get("http://www.google.com"))

if __name__ == "__main__":
    main()
