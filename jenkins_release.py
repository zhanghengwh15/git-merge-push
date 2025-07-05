#!/usr/bin/env python3
import sys
import requests
import json

# Jenkins 配置（请根据实际情况修改）
JENKINS_URL = 'http://192.168.100.43:8080'
JENKINS_USER = 'developer'
JENKINS_PASS = 'developer'


def parse_args():
    if len(sys.argv) < 2:
        print('用法: ./jenkins_release.py <job_name> [param1=val1 param2=val2 ...]')
        sys.exit(1)
    job_name = sys.argv[1]
    params = {}
    for arg in sys.argv[2:]:
        if '=' in arg:
            k, v = arg.split('=', 1)
            params[k] = v
    return job_name, params


def trigger_jenkins_job(job_name, params):
    url = f"{JENKINS_URL}/job/{job_name}/buildWithParameters"
    auth = (JENKINS_USER, JENKINS_PASS)
    resp = requests.post(url, auth=auth, params=params)
    if resp.status_code in (201, 200):
        print(f"Jenkins Job '{job_name}' 触发成功！")
    else:
        print(f"触发失败，状态码: {resp.status_code}")
        print(resp.text)
        sys.exit(2)


def main():
    job_name, params = parse_args()
    trigger_jenkins_job(job_name, params)

if __name__ == '__main__':
    main() 