FROM 3mdeb/edk2

WORKDIR /home/edk2

ENV REPO="https://github.com/tianocore/edk2.git"
ENV BRANCH="vUDK2018"
RUN git clone $REPO $BRANCH

WORKDIR /home/edk2/${BRANCH}
RUN git submodule update --init

RUN make -C BaseTools
ADD edk2/Conf/* /home/edk2/${BRANCH}/Conf/
RUN /bin/bash -c "cd /home/edk2/${BRANCH} && . edksetup.sh && build -DSECURE_BOOT_ENABLE=TRUE"

