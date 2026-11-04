# Risk Scoring APIs

All endpoints need `Authorization: Bearer <token>`. Ids are prefixed: `domain_1`, `risk_5`, `scan_3`.

Response envelope:

```json
{ "success": true, "message": "...", "data": {} }
```

Errors: `{ "success": false, "message": "..." }`

| Status | Meaning |
|--------|---------|
| 400 | Bad params/query, e.g. `Invalid request: params.id: Must look like domain_1` |
| 401 | Missing/invalid token |
| 404 | Not found, or not owned by the user |

Score is recalculated automatically after every scan that ends `COMPLETED` or `PARTIAL`.

Levels: `low` 0-19, `moderate` 20-39, `high` 40-59, `very_high` 60-79, `critical` 80-100.

---

## GET /domain/:id/risk-score

Latest score, change vs previous scan, and top 5 open risks.

Request: `GET /domain/domain_1/risk-score`

Response `200`:

```json
{
  "success": true,
  "message": "Risk score fetched successfully",
  "data": {
    "domain": { "id": "domain_1", "name": "Example", "url": "https://example.com" },
    "id": "risk_score_4",
    "domainId": "domain_1",
    "scanId": "scan_7",
    "score": 46,
    "level": "high",
    "levelLabel": "High",
    "previousScore": 38,
    "delta": 8,
    "findingCount": 6,
    "bySeverity": { "critical": 1, "high": 1, "medium": 2, "low": 1, "info": 1 },
    "byCategory": { "exposed_resource": 0, "port": 40, "ssl": 0, "header": 6, "technology": 0 },
    "breakdown": [
      { "category": "port", "findings": 2, "rawPoints": 43, "points": 40, "cap": 50 }
    ],
    "calculatedAt": "2026-11-03T09:30:00.000Z",
    "topRisks": [
      {
        "id": "risk_12",
        "domainId": "domain_1",
        "category": "port",
        "ruleId": "port.redis.exposed",
        "title": "Redis (6379/tcp) exposed on 1.2.3.4",
        "severity": "critical",
        "scoreContribution": 40,
        "affectedAssets": [
          { "type": "subdomain", "id": "subdomain_2", "hostname": "api.example.com", "ipAddress": "1.2.3.4" }
        ],
        "status": "OPEN",
        "firstSeenAt": "2026-11-01T10:00:00.000Z",
        "lastSeenAt": "2026-11-03T09:30:00.000Z",
        "resolvedAt": null
      }
    ]
  }
}
```

Extra errors: `404 No risk score yet, run a scan first` (domain never scanned), `404 Domain not found`.

---

## GET /domain/:id/risks

Paginated risk findings for a domain. Sorted OPEN first, then by severity, then contribution.

Query (all optional):

| Param | Values | Default |
|-------|--------|---------|
| `status` | `OPEN`, `RESOLVED`, `ALL` | `OPEN` |
| `severity` | comma list: `critical,high,medium,low,info` | all |
| `category` | `exposed_resource`, `port`, `ssl`, `header`, `technology` | all |
| `page` | int >= 1 | 1 |
| `limit` | int 1-100 | 50 |

Request: `GET /domain/domain_1/risks?severity=critical,high&status=OPEN&page=1&limit=20`

Response `200`:

```json
{
  "success": true,
  "message": "Risks fetched successfully",
  "data": {
    "items": [
      {
        "id": "risk_12",
        "domainId": "domain_1",
        "category": "port",
        "ruleId": "port.redis.exposed",
        "title": "Redis (6379/tcp) exposed on 1.2.3.4",
        "description": "Redis is reachable from the internet on 1.2.3.4:6379, used by api.example.com.",
        "severity": "critical",
        "scoreContribution": 40,
        "affectedAssets": [
          { "type": "subdomain", "id": "subdomain_2", "hostname": "api.example.com", "ipAddress": "1.2.3.4" }
        ],
        "remediation": "Block port 6379 at the firewall immediately, bind Redis to localhost or a private network, and enable authentication (requirepass/ACLs).",
        "status": "OPEN",
        "firstSeenAt": "2026-11-01T10:00:00.000Z",
        "lastSeenAt": "2026-11-03T09:30:00.000Z",
        "resolvedAt": null
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
  }
}
```

---

## GET /risk/:id

Full detail of one finding, including evidence.

Request: `GET /risk/risk_12`

Response `200`:

```json
{
  "success": true,
  "message": "Risk fetched successfully",
  "data": {
    "id": "risk_12",
    "domainId": "domain_1",
    "fingerprint": "port.exposed:1.2.3.4:6379/tcp",
    "category": "port",
    "ruleId": "port.redis.exposed",
    "title": "Redis (6379/tcp) exposed on 1.2.3.4",
    "description": "Redis is reachable from the internet on 1.2.3.4:6379, used by api.example.com.",
    "severity": "critical",
    "scoreContribution": 40,
    "evidence": {
      "address": "1.2.3.4",
      "port": 6379,
      "protocol": "tcp",
      "service": "redis",
      "state": "open",
      "lastSeenAt": "2026-11-03T09:29:00.000Z",
      "hostnames": ["api.example.com"]
    },
    "affectedAssets": [
      { "type": "subdomain", "id": "subdomain_2", "hostname": "api.example.com", "ipAddress": "1.2.3.4" }
    ],
    "remediation": "Block port 6379 at the firewall immediately, ...",
    "status": "OPEN",
    "firstSeenAt": "2026-11-01T10:00:00.000Z",
    "lastSeenAt": "2026-11-03T09:30:00.000Z",
    "resolvedAt": null,
    "lastScanId": "scan_7",
    "createdAt": "2026-11-01T10:00:00.000Z",
    "updatedAt": "2026-11-03T09:30:00.000Z",
    "domain": { "id": "domain_1", "name": "Example", "url": "https://example.com" },
    "lastScan": {
      "id": "scan_7",
      "status": "COMPLETED",
      "startedAt": "2026-11-03T09:28:00.000Z",
      "completedAt": "2026-11-03T09:30:00.000Z"
    }
  }
}
```

`evidence` shape depends on `category`. `affectedAssets` items are `{type:"subdomain",...}` or `{type:"url", url}`.

Extra error: `404 Risk not found`.

---

## GET /domain/:id/risk-history

Score per scan, newest first.

Query (all optional): `since` (ISO date), `page` (default 1), `limit` (1-100, default 50).

Request: `GET /domain/domain_1/risk-history?since=2026-10-01&limit=10`

Response `200`:

```json
{
  "success": true,
  "message": "Risk history fetched successfully",
  "data": {
    "items": [
      {
        "id": "risk_score_4",
        "domainId": "domain_1",
        "scanId": "scan_7",
        "score": 46,
        "level": "high",
        "levelLabel": "High",
        "previousScore": 38,
        "delta": 8,
        "findingCount": 6,
        "bySeverity": { "critical": 1, "high": 1, "medium": 2, "low": 1, "info": 1 },
        "byCategory": { "exposed_resource": 0, "port": 40, "ssl": 0, "header": 6, "technology": 0 },
        "calculatedAt": "2026-11-03T09:30:00.000Z"
      }
    ],
    "pagination": { "page": 1, "limit": 10, "total": 1, "totalPages": 1 }
  }
}
```

`previousScore` and `delta` are `null` for the first scan. History items omit `breakdown`.
