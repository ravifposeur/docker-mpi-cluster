/**
 * pi.c — Monte Carlo estimation of Pi
 * ============================================================
 * Setiap proses menghitung sejumlah sampel acak dalam kuadran
 * [0,1] x [0,1], lalu hasilnya dikurangi (MPI_Reduce) ke rank 0.
 *
 * Build : lihat Makefile di folder ini
 * Run   : mpirun --hostfile ../config/hostfile -np <N> ./pi
 * ============================================================
 */

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifndef DEFAULT_SAMPLES
#define DEFAULT_SAMPLES 100000000LL
#endif

int main(int argc, char **argv) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    long long n = DEFAULT_SAMPLES;
    if (argc > 1) n = atoll(argv[1]);

    long long per = n / size;

    char hostname[256];
    gethostname(hostname, sizeof(hostname));

    /* Seed unik per rank */
    srand((unsigned)time(NULL) ^ (rank * 2654435761u));

    long long inside = 0;
    for (long long i = 0; i < per; i++) {
        double x = (double)rand() / RAND_MAX;
        double y = (double)rand() / RAND_MAX;
        if (x * x + y * y <= 1.0) inside++;
    }

    printf("[rank %d/%d] host=%-8s samples=%lld inside=%lld\n",
           rank, size, hostname, per, inside);
    fflush(stdout);

    long long total = 0;
    MPI_Reduce(&inside, &total, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double pi = 4.0 * (double)total / (double)(per * size);
        printf("\n============================================\n");
        printf("  Proses     : %d\n", size);
        printf("  Total sampel: %lld\n", per * size);
        printf("  Pi estimate : %.10f\n", pi);
        printf("  Error       : %.2e\n", pi - 3.14159265358979);
        printf("============================================\n");
    }

    MPI_Finalize();
    return 0;
}
