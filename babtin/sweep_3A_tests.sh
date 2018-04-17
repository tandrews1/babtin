
main () {
   local width=$1
   local depth=$2
   if [ "$width" == "" ]; then
      width=1
   fi
   if [ "$depth" == "" ]; then
      depth=1
   fi
   GO_TEST_SRC=/home/taylor/git/6.824/labs/lab-dev/src/kvraft
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
main $*
