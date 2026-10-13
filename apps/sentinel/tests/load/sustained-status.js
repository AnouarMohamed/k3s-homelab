import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    sustained: {
      executor: 'constant-arrival-rate',
      rate: 5,
      timeUnit: '1s',
      duration: '10m',
      preAllocatedVUs: 5,
      maxVUs: 20,
    },
  },
  thresholds: {
    checks: ['rate>0.995'],
    http_req_duration: ['p(99)<750'],
    http_req_failed: ['rate<0.005'],
  },
};

const baseURL = __ENV.SENTINEL_BASE_URL || 'http://sentinel-api.apps-sentinel.svc:8080';

export default function () {
  const response = http.get(`${baseURL}/api/v1/status`, {
    tags: { scenario: 'sustained', endpoint: 'status' },
  });
  check(response, {
    'status is successful': (result) => result.status === 200,
    'response is JSON': (result) =>
      result.headers['Content-Type']?.startsWith('application/json'),
  });
  sleep(0.2);
}
