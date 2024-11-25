# Web App Topology with Horizontal Scalability

This figure shows a web server cluster with load balancing.
It is built with four servers that can be expanded to include additional web hosts or service hosts.

This starter topology uses `web1` as a web host and the primary `nginx` proxy. The `web` hosts are connected to a PostgreSQL database server, `pg1`. The `pg1` server is backed up by `pg2` using a rolling snapshot backup strategy.

```mermaid
graph BT
    linkStyle default stroke-width:3px
    user1[Web User 1] -->|Browser Connection| nginx[Nginx on web1]
    user2[Web User 2] -->|Browser Connection| nginx
    nginx -.->|Upstream Connection| web1[Web Server web1]
    nginx -.->|Upstream Connection| web2[Web Server web2]
    web1 -->|Database Access| pg1[PostgreSQL pg1]
    web2 -->|Database Access| pg1
    pg2[PostgreSQL pg2] -->|Rolling Snapshot Backup| pg1

    subgraph web1_components [Web1 Host]
        direction TB
        style web1_components stroke-dasharray: 5 5
        nginx
        web1
    end
```
