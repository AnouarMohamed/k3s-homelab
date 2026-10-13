import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    baseline: {
      executor: 'ramping-vus',
      stages: [
        { duration: '30s', target: 5 },
        { duration: '2m', target: 10 },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    checks: ['rate>0.99'],
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const baseURL = __ENV.SENTINEL_BASE_URL || 'http://sentinel-api.apps-sentinel.svc:8080';

export default function () {
  const response = http.get(`${baseURL}/api/v1/status`, {
    tags: { scenario: 'baseline', endpoint: 'status' },
  });
  check(response, {
    'status is successful': (result) => result.status === 200,
    'response contains services': (result) => Array.isArray(result.json('services')),
  });
  sleep(1);
}
