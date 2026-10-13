import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    status_readers: {
      executor: 'constant-vus',
      vus: 5,
      duration: '1m',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const baseURL = __ENV.SENTINEL_BASE_URL || 'http://127.0.0.1:8080';

export default function () {
  const response = http.get(`${baseURL}/api/v1/status`, {
    tags: { endpoint: 'status' },
  });
  check(response, {
    'status API returns 200': (result) => result.status === 200,
    'status API returns JSON': (result) =>
      result.headers['Content-Type']?.startsWith('application/json'),
    'status API has services': (result) =>
      Array.isArray(result.json('services')),
  });
}
