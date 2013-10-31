#!/usr/sbin/dtrace -s

#pragma D option quiet

inline int TOP_FILES = 10;

dtrace:::BEGIN
{
        printf("Tracing... Hit Ctrl-C to end.\n");
}

nfsv3:::op-read-start,
nfsv3:::op-write-start
{
        start[args[1]->noi_xid] = timestamp;
}

nfsv3:::op-read-done,
nfsv3:::op-write-done
/start[args[1]->noi_xid]!= 0/
{
        this->elapsed = timestamp - start[args[1]->noi_xid];
        @rw[probename == "op-read-done"? "read": "write"] =
            quantize(this->elapsed / 1000);
        @host[args[0]->ci_remote] = sum(this->elapsed);
        @file[args[1]->noi_curpath] = sum(this->elapsed);
        start[args[1]->noi_xid] = 0;
}

dtrace:::END
{
        printf("NFSv3 read/write distributions (us):\n");
        printa(@rw);

        printf("\nNFSv3 read/write by host (total us):\n");
        normalize(@host, 1000);
        printa(@host);

        printf("\nNFSv3 read/write top%d files (total us):\n", TOP_FILES);
        normalize(@file, 1000);
        trunc(@file, TOP_FILES);
        printa(@file);
}
