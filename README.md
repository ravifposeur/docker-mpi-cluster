# MPI Cluster Simulation

A Docker-based MPI cluster simulation for High-Performance Computing (HPC) coursework. This project emulates a multi-node cluster on a single physical machine using containerization, complete with monitoring stack and automated benchmarking.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Benchmarking](#benchmarking)
- [Monitoring](#monitoring)
- [Makefile Reference](#makefile-reference)
- [Troubleshooting](#troubleshooting)
- [Design Notes](#design-notes)

---

## Overview

This project simulates a computational cluster consisting of one master node and three worker nodes, all running OpenMPI on Ubuntu 22.04. The cluster is interconnected through an isolated Docker bridge network and shares a common filesystem via bind mounts, mimicking the behavior of NFS in a physical cluster.

The primary objective is to demonstrate distributed parallel computing using MPI on a resource-constrained environment, while providing measurable performance data through automated benchmarking.

### Features

- Multi-node MPI execution using OpenMPI
- Isolated Docker bridge network for inter-node communication
- Shared storage across all nodes (bind mount simulation of NFS)
- SSH key-based authentication between nodes, no password required
- Automated benchmark for Monte Carlo Pi estimation
- Real-time monitoring with Prometheus, Grafana, and cAdvisor
- Auto-provisioned Grafana dashboard
- Fully reproducible setup via Docker Compose and Makefile

---

## Architecture

```
+---------------------------------------------------------------+
|                    Docker Bridge Network: mpinet              |
|                                                               |
|   +-----------+   +-----------+   +-----------+   +---------+ |
|   |  master   |   |  worker1  |   |  worker2  |   | worker3 | |
|   |  OpenMPI  |   |  OpenMPI  |   |  OpenMPI  |   | OpenMPI | |
|   +-----+-----+   +-----+-----+   +-----+-----+   +----+----+ |
|         |               |               |              |      |
|         +---------------+---------------+--------------+      |
|                         |                                     |
|         +---------------+----------------+                    |
|         |               |                |                    |
|   +-----v-----+   +-----v-----+   +------v------+             |
|   | Prometheus|   |  Grafana  |   |  cAdvisor   |             |
|   +-----------+   +-----------+   +-------------+             |
|                                                               |
|   Shared Volume: ./shared mounted at /shared on all nodes     |
+---------------------------------------------------------------+
        |                    |                |
     :9090                :3000            :8080
   Prometheus            Grafana          cAdvisor
```

### Component Summary

| Component | Role | Base Image |
|-----------|------|------------|
| master | MPI process coordinator and rank 0 host | ubuntu:22.04 + OpenMPI |
| worker1-3 | MPI compute nodes | ubuntu:22.04 + OpenMPI |
| Prometheus | Metric aggregation and time-series storage | prom/prometheus |
| Grafana | Visualization and dashboards | grafana/grafana |
| cAdvisor | Container-level metric exporter | gcr.io/cadvisor/cadvisor |

---

## Prerequisites

- Docker Engine version 20.10 or newer
- Docker Compose v2 (invoked as `docker compose`)
- Minimum 4 GB of RAM available for containers
- Linux, macOS, or Windows with WSL2
- GNU Make (optional, for convenience commands)

Verify installation:

```bash
docker --version
docker compose version
make --version
```

---

## Project Structure

```
mpi-cluster/
├── compose.yaml                        Docker Compose orchestration
├── .env                                Central configuration
├── Makefile                            Convenience commands
├── README.md                           This file
├── docs/
│   ├── ARCHITECTURE.md                 Detailed architecture documentation
│   ├── BENCHMARK.md                    Benchmark methodology and analysis
│   └── TROUBLESHOOTING.md              Common issues and solutions
├── docker/
│   ├── mpi-node/
│   │   ├── Dockerfile                  Image definition for MPI nodes
│   │   └── entrypoint.sh               Container startup script
│   └── monitoring/
│       ├── prometheus/
│       │   └── prometheus.yml          Prometheus scrape configuration
│       └── grafana/
│           └── provisioning/
│               ├── datasources/
│               │   └── prometheus.yml  Auto-provisioned datasource
│               └── dashboards/
│                   ├── dashboard.yml   Dashboard provider config
│                   └── mpi-cluster.json Pre-built dashboard definition
├── config/
│   └── hostfile                        MPI host definitions
├── src/
│   ├── pi.c                            Monte Carlo Pi estimation
│   └── Makefile                        Build rules for MPI programs
├── scripts/
│   ├── ssh-setup.sh                    SSH connectivity verification
│   ├── run-benchmark.sh                Automated benchmark runner
│   └── collect-metrics.sh              Metric snapshot utility
├── shared/                             Shared storage across all nodes
└── results/                            Benchmark outputs and metrics
```

### Directory Purpose

| Directory | Purpose |
|-----------|---------|
| `docker/mpi-node/` | Defines the MPI node image with OpenMPI and SSH pre-configured |
| `docker/monitoring/` | Contains configuration for Prometheus and Grafana |
| `config/` | Stores the MPI hostfile, mounted read-only into all nodes |
| `src/` | Source code for MPI programs and their build rules |
| `scripts/` | Shell automation for setup, benchmarking, and metric collection |
| `shared/` | Bind-mounted at `/shared` on all nodes, simulating shared storage |
| `results/` | Output directory for benchmark CSV and metric JSON files |
| `docs/` | Extended documentation |

---

## Quick Start

```bash
# 1. Clone or create the project directory
cd mpi-cluster

# 2. Build images and start all containers
make up

# 3. Verify all containers are running
make ps

# 4. Enter the master node
make shell

# 5. From inside the master container, run the benchmark
/scripts/run-benchmark.sh

# 6. Exit the container
exit
```

Access the monitoring interfaces from the host machine:

- Grafana: http://localhost:3000 (default credentials: admin / admin)
- Prometheus: http://localhost:9090
- cAdvisor: http://localhost:8080

To stop the cluster:

```bash
make down
```

To remove all containers and volumes:

```bash
make clean
```

---

## Configuration

All tunable parameters are defined in the `.env` file at the project root.

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPOSE_PROJECT_NAME` | mpi-cluster | Prefix applied to all container names |
| `WORKER_COUNT` | 3 | Number of worker nodes to run |
| `SLOTS_PER_NODE` | 2 | MPI process slots available per node |
| `PI_SAMPLES` | 100000000 | Number of random samples for Pi estimation |
| `BENCHMARK_NP_LIST` | "1 2 4 8" | List of process counts to benchmark |
| `SSH_USER` | root | User account used for inter-node SSH |
| `SSH_PASSWORD` | root | Password for the SSH user (fallback only) |
| `PORT_CADVISOR` | 8080 | Host port mapped to cAdvisor |
| `PORT_PROMETHEUS` | 9090 | Host port mapped to Prometheus |
| `PORT_GRAFANA` | 3000 | Host port mapped to Grafana |
| `GRAFANA_USER` | admin | Grafana administrator username |
| `GRAFANA_PASSWORD` | admin | Grafana administrator password |

Modify these values and re-run `make up` for the changes to take effect.

---

## Usage

### Starting the Cluster

```bash
make up
```

This builds the MPI node image and starts all eight containers. The first build takes approximately two to three minutes.

### Accessing a Node

```bash
# Enter the master container
make shell

# Or access a specific worker
docker exec -it worker1 bash
```

### Verifying Inter-Node Connectivity

Once inside the master container:

```bash
/scripts/ssh-setup.sh
```

Expected output:

```
==> Verifying SSH connectivity to each worker...
  [OK] worker1
  [OK] worker2
  [OK] worker3
==> All nodes reachable.
```

### Running an MPI Program Manually

```bash
# Inside the master container
mpicc /src/pi.c -o /shared/pi
mpirun --hostfile /config/hostfile --allow-run-as-root -np 8 /shared/pi 100000000
```

The binary must reside in `/shared` or another bind-mounted directory, as it needs to be accessible from every node. Placing it in `/tmp` or the home directory will result in an "unable to access or execute" error.

### Hostfile Format

The hostfile at `config/hostfile` uses the standard OpenMPI format:

```
master    slots=2
worker1   slots=2
worker2   slots=2
worker3   slots=2
```

The total number of slots determines the maximum value for `-np`. With four nodes and two slots each, `-np 8` is the upper limit before oversubscription is required.

---

## Benchmarking

The benchmark uses Monte Carlo simulation to estimate the value of Pi. Each MPI rank generates a fixed number of random samples and counts how many fall inside the unit circle. The partial counts are summed using `MPI_Reduce` at rank 0.

### Running the Benchmark

```bash
# Inside the master container
/scripts/run-benchmark.sh
```

The script performs the following steps:

1. Compiles `src/pi.c` to `/shared/pi`
2. Iterates through process counts defined in `BENCHMARK_NP_LIST`
3. Records elapsed time for each run
4. Appends results to `results/benchmark.csv`

### Output Format

```csv
np,samples,time_seconds,pi_estimate
1,100000000,8.234,3.1415926536
2,100000000,4.312,3.1415926536
4,100000000,2.345,3.1415926536
8,100000000,1.567,3.1415926536
```

### Calculating Speedup and Efficiency

```bash
T1=$(grep '^1,' /results/benchmark.csv | cut -d, -f3)
while IFS=, read -r np samples time pi; do
    [ "$np" = "np" ] && continue
    speedup=$(echo "scale=2; $T1 / $time" | bc)
    eff=$(echo "scale=2; $speedup / $np * 100" | bc)
    echo "$np,$time,$speedup,$eff%"
done < /results/benchmark.csv
```

| Metric | Formula | Interpretation |
|--------|---------|----------------|
| Speedup | S(n) = T(1) / T(n) | How much faster than serial execution |
| Efficiency | E(n) = S(n) / n | Fraction of parallel capacity utilized |

Efficiency typically decreases as the number of processes increases, due to the O(log n) overhead of `MPI_Reduce` and reduced computation per process.

Refer to `docs/BENCHMARK.md` for detailed methodology and analysis guidelines.

---

## Monitoring

### Prometheus

Prometheus scrapes container metrics from cAdvisor every five seconds. Access the web interface at http://localhost:9090.

Useful endpoints:

- `/targets` — displays scrape target status
- `/graph` — interactive PromQL query interface

### Grafana

Grafana is auto-provisioned with a Prometheus datasource and a pre-built dashboard titled "MPI Cluster Overview". Access it at http://localhost:3000.

Default credentials: `admin` / `admin`

The dashboard contains four panels:

1. CPU Usage per Container
2. Memory Usage per Container
3. Network Receive Throughput
4. Network Transmit Throughput

During benchmark execution, the CPU panel will display simultaneous spikes across master, worker1, worker2, and worker3, confirming even distribution of workload.

### cAdvisor

cAdvisor collects container-level resource metrics and exposes them at http://localhost:8080. Prometheus scrapes this endpoint to populate the Grafana dashboards.

---

## Makefile Reference

The root Makefile provides shortcuts for common operations. Run `make help` to display all available targets.

| Target | Description |
|--------|-------------|
| `make help` | Display available commands |
| `make up` | Build images and start all containers |
| `make down` | Stop and remove all containers |
| `make restart` | Restart all containers without rebuilding |
| `make build` | Build images only, without starting |
| `make ps` | Show container status |
| `make logs` | Follow logs from all containers |
| `make shell` | Open an interactive shell in the master container |
| `make benchmark` | Run the benchmark script inside the master container |
| `make metrics` | Snapshot Prometheus metrics to the results directory |
| `make clean` | Remove containers, volumes, and benchmark outputs |

### Example Workflows

```bash
# Full setup from scratch
make up
make shell
/scripts/run-benchmark.sh
exit

# View real-time logs
make logs

# Restart after configuration change
make restart

# Tear down completely
make clean
```

---

## Troubleshooting

### mpirun hangs or fails to launch

**Symptom:** The command does not return, or reports "unable to launch the specified application".

**Cause:** The binary is not accessible from the worker nodes.

**Solution:** Ensure the executable resides in a shared directory such as `/shared`, `/src`, or another bind-mounted path. Verify with:

```bash
ssh worker1 ls -la /shared/pi
```

### SSH connection refused between nodes

**Cause:** SSH daemon not running, or keys not properly propagated.

**Solution:** Verify the SSH service is running:

```bash
docker exec master service ssh status
```

If the daemon is running but authentication fails, check that `/root/.ssh/authorized_keys` exists and contains the public key:

```bash
docker exec master cat /root/.ssh/authorized_keys
```

### Grafana shows "No data"

**Cause:** Prometheus is not scraping cAdvisor, or the dashboard query does not match available labels.

**Solution:**

1. Verify target status at http://localhost:9090/targets. The cAdvisor target must report `UP`.
2. Test the query in Prometheus at http://localhost:9090/graph:

```promql
rate(container_cpu_usage_seconds_total{name=~"master|worker.*"}[1m])
```

3. If the query returns no results, inspect the available container labels:

```bash
curl -s "http://localhost:9090/api/v1/query?query=container_last_seen" \
  | python3 -m json.tool | grep '"name"'
```

### Port already in use

**Symptom:** A container exits immediately after startup with a bind error.

**Solution:** Another process is using the same host port. Either stop the conflicting process or change the port mapping in `.env`:

```bash
PORT_GRAFANA=3001
PORT_PROMETHEUS=9091
PORT_CADVISOR=8081
```

Then re-run:

```bash
make down
make up
```

### Insufficient memory

**Symptom:** Containers are killed by the OOM killer.

**Solution:** Reduce the number of workers in `compose.yaml`, or lower `PI_SAMPLES` in `.env`.

Refer to `docs/TROUBLESHOOTING.md` for additional scenarios.

---

## Design Notes

### Why Docker Instead of Virtual Machines

Virtual machines run a complete operating system per node, consuming several gigabytes of RAM each. Docker containers share the host kernel and isolate only the process namespace, filesystem, and network. This reduces the memory footprint by an order of magnitude, allowing four MPI nodes plus monitoring to run comfortably on a single development machine.

For the purposes of MPI benchmarking, the isolation provided by container namespaces is sufficient. Each container has its own hostname, IP address, and filesystem view, which is functionally equivalent to a physical node from the perspective of OpenMPI.

### Why Bind Mounts Instead of NFS

In a production cluster, shared storage is provided by NFS, Lustre, or similar network filesystems. In this simulation, a bind mount from the host directory `./shared` to `/shared` on each container provides the same visibility semantics: a file written by one node is immediately visible to all others. This eliminates the complexity of running an NFS server inside the cluster while preserving the functional behavior that MPI requires.

### Single cAdvisor Instance

Rather than running cAdvisor inside each MPI node (which would consume additional resources per container), a single cAdvisor instance runs on the Docker bridge network and collects metrics from all containers through the Docker socket. This approach is standard practice and simplifies the monitoring stack.

### Reproducibility

The entire cluster is defined declaratively through `compose.yaml`, `Dockerfile`, and configuration files. A fresh clone of this repository can be brought to a fully functional state with a single command (`make up`). This ensures that results are reproducible and that teammates can replicate the environment without manual intervention.

---

## References

- OpenMPI Documentation: https://www.open-mpi.org/doc/
- Docker Compose Reference: https://docs.docker.com/compose/
- Prometheus Documentation: https://prometheus.io/docs/
- Grafana Provisioning: https://grafana.com/docs/grafana/latest/administration/provisioning/
- cAdvisor Repository: https://github.com/google/cadvisor

---

## License

This project is developed for academic purposes as part of a High-Performance Computing course. It is provided as-is without warranty. Attribution is appreciated for any reuse.
