
barrage-all () {
   GO_TEST_PKG=TestBasic3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestConcurrent3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestUnreliable3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestUnreliableOneKey3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestOnePartition3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestManyPartitionsOneClient3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestManyPartitionsManyClients3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistOneClient3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistConcurrent3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistConcurrentUnreliable3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistPartition3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistPartitionUnreliable3A ./barrage.sh $width $depth &
   sleep 1
   GO_TEST_PKG=TestPersistPartitionUnreliableLinearizable3A ./barrage.sh $width $depth &
}

run-one () {
   export GO_TEST_PKG=$1
   echo $GO_TEST_PKG
   sleep 4
   time go test -run $GO_TEST_PKG 2>&1 |tee /tmp/kvoutput
   return ${PIPESTATUS[0]}
}

run-precheckin () {
   run-one TestBasic3A && \
      run-one TestConcurrent3A && \
      run-one TestUnreliable3A && \
      run-one TestUnreliableOneKey3A && \
      run-one TestOnePartition3A && \
      run-one TestManyPartitionsOneClient3A && \
      run-one TestManyPartitionsManyClients3A && \
      run-one TestPersistOneClient3A && \
      run-one TestPersistConcurrent3A && \
      run-one TestPersistConcurrentUnreliable3A && \
      run-one TestPersistPartition3A && \
      run-one TestPersistPartitionUnreliable3A && \
      run-one TestPersistPartitionUnreliableLinearizable3A
}

run-line-in-sand () {
   return 
}

main () {
   local cmd=$1
   export GO_TEST_SRC=/home/taylor/git/6.824/labs/lab-dev/src/kvraft
   cd $GO_TEST_SRC
   run-$cmd
}
main $*
