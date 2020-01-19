program testPinnedMemory
!! Focal test program
!!
!! Tests host-to-device and device-to-host transfers using pinned host memory
!!  for all Focal abstracted data types as well as un-typed general deviceBuffers
!! 

use Focal
use Focal_Test_Utils
use iso_fortran_env, only: sp=>real32, dp=>real64
implicit none

character(*), parameter :: test_string = 'Hello world'

real(sp), dimension(:), pointer :: hostReal32_1, hostReal32_2
real(dp), dimension(:), pointer :: hostReal64_1, hostReal64_2
integer, dimension(:), pointer :: hostInt32_1, hostInt32_2

type(c_ptr) :: char_ptr_1, char_ptr_2
character(len=1), dimension(:), pointer :: hostChar_1, hostChar_2

type(fclDeviceFloat) :: deviceReal32_1,deviceReal32_2
type(fclDeviceDouble) :: deviceReal64_1, deviceReal64_2
type(fclDeviceInt32) :: deviceInt32_1, deviceInt32_2
type(fclDeviceBuffer) :: deviceBuffer_1, deviceBuffer_2

integer :: i
character(len=1), parameter :: cc = 'a'
integer(c_int64_t) :: strNBytes

strNBytes = c_sizeof(cc)*len(test_string)

! --- Initialise ---
call fclTestInit()

! --- Initialise typed device buffers ---
deviceReal32_1 = fclBufferFloat(FCL_TEST_SIZE,read=.true.,write=.false.)
deviceReal64_1 = fclBufferDouble(FCL_TEST_SIZE,read=.true.,write=.false.)
deviceInt32_1 = fclBufferInt32(FCL_TEST_SIZE,read=.true.,write=.false.)

deviceReal32_2 = fclBufferFloat(FCL_TEST_SIZE,read=.true.,write=.false.)
deviceReal64_2 = fclBufferDouble(FCL_TEST_SIZE,read=.true.,write=.false.)
deviceInt32_2 = fclBufferInt32(FCL_TEST_SIZE,read=.true.,write=.false.)

! --- Manually initialise un-typed buffer objects ---
deviceBuffer_1%cmdq => fclDefaultCmdQ
deviceBuffer_1%nBytes = strNBytes
deviceBuffer_1%cl_mem = fclBuffer(fclDefaultCmdQ,strNBytes,read=.true.,write=.true.)

deviceBuffer_2%cmdq => fclDefaultCmdQ
deviceBuffer_2%nBytes = strNBytes
deviceBuffer_2%cl_mem = fclBuffer(fclDefaultCmdQ,strNBytes,read=.true.,write=.true.)

! --- Initialise host arrays (pinned) ---
call fclAllocHost(hostReal32_1,FCL_TEST_SIZE)
call fclAllocHost(hostReal32_2,FCL_TEST_SIZE)
call fclAllocHost(hostReal64_1,FCL_TEST_SIZE)
call fclAllocHost(hostReal64_2,FCL_TEST_SIZE)
call fclAllocHost(hostInt32_1,FCL_TEST_SIZE)
call fclAllocHost(hostInt32_2,FCL_TEST_SIZE)

char_ptr_1 = fclAllocHostPtr(fclDefaultCmdq,strNBytes)
char_ptr_2 = fclAllocHostPtr(fclDefaultCmdq,strNBytes)

call c_f_pointer(char_ptr_1,hostChar_1,[len(test_string)])
call c_f_pointer(char_ptr_2,hostChar_2,[len(test_string)])

! --- Setup host arrays ---
do i=1,FCL_TEST_SIZE
  hostReal32_1(i) = i
  hostReal64_1(i) = 2*i
  hostInt32_1(i) = 3*i
end do

do i=1,len(test_string)
  hostChar_1(i) = test_string(i:i)
end do

! --- Perform host-to-device transfer ---
deviceReal32_1 = hostReal32_1
deviceReal64_1 = hostReal64_1
deviceInt32_1 = hostInt32_1
call fclMemWrite(deviceBuffer_1,c_loc(hostChar_1),deviceBuffer_1%nBytes)

! --- Perform device-to-device transfer ---
deviceReal32_2 = deviceReal32_1
deviceReal64_2 = deviceReal64_1
deviceInt32_2 = deviceInt32_1
call fclMemCopy(deviceBuffer_2,deviceBuffer_1)

! --- Perform device-to-host transfer ---
hostReal32_2 = deviceReal32_2
hostReal64_2 = deviceReal64_2
hostInt32_2 = deviceInt32_2
call fclMemRead(c_loc(hostChar_2),deviceBuffer_2,deviceBuffer_2%nBytes)

! --- Check arrays ---
call fclTestAssertEqual(hostReal32_1,hostReal32_2,'hostReal32_1 == hostReal32_2 (1)')
call fclTestAssertEqual(hostReal64_1,hostReal64_2,'hostReal64_1 == hostReal64_2 (1)')
call fclTestAssertEqual(hostInt32_1,hostInt32_2,'hostInt32_1 == hostInt32_2 (1)')
call fclTestAssertEqual(hostChar_1,hostChar_2,'hostChar_1 == hostChar_2 (1)')

call fclTestFinish()

end program testPinnedMemory
! -----------------------------------------------------------------------------