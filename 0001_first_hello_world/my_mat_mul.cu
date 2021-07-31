#include <cuda_runtime.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cassert>

using namespace std;

// 用宏变长参数来实现
#define CUDA_CALL(...) {cudaError_t _cuda_tep_set_not_repeat_a=(__VA_ARGS__);if (_cuda_tep_set_not_repeat_a!=cudaSuccess){printf("\nCUDA ERROR: %s (err_num=%d)\n", cudaGetErrorString(_cuda_tep_set_not_repeat_a), _cuda_tep_set_not_repeat_a); cudaDeviceReset(); assert(0);} }
#define CUDA_LAST_ERROR() CUDA_CALL(cudaGetLastError())

#define SHOW_MAT(a, m,n) \
{\
  cout<<"ShowMat: "<<#a<<endl;\
  for (int i=0;i<m;++i){\
    for (int j=0;j<n;++j){\
      cout<<a[i*n+j]<<", ";\
    }\
    cout<<endl;\
  }\
}

__global__ void matmult_v1(float *a, float *b, float *c, int m, int n, int k){//a-> m*k  b->k*n

  int idx = blockDim.x * blockIdx.x + threadIdx.x;
  int idy=blockIdx.y*blockDim.y+threadIdx.y;
  int index=gridDim.x*blockDim.x*idy+idx;
  if (idx>=n || idy>=m) return;
  
  c[index]=0;
  for (int i=0;i<k;++i){
    c[index]+=a[idy*k+i]*b[idx+i*n];
  }
}

int main(){
  int m=4;
  int n=5;
  int k=3;

  float *A=new float[m*k]{1,2,3,4,5,6,7,8,9,10,11};
  float *B=new float[k*n]{1,0,1,0,1,0,0,1,1,0,1,1,0};
  float *C=new float[m*n]{0};

  float *ga, *gb, *gc;
  // GPU端分配内存
  cudaMalloc((void**)&ga, m*k*sizeof(float));
  cudaMalloc((void**)&gb, k*n*sizeof(float));
  cudaMalloc((void**)&gc, m*n*sizeof(float));

  // CPU的数据拷贝到GPU端
  cudaMemcpy(ga, A, m*k*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(gb, B, k*n*sizeof(float), cudaMemcpyHostToDevice);
  //cudaMemcpy(gc, C, size, cudaMemcpyHostToDevice);

  // 定义kernel执行配置，（1024*1024/512）个block，每个block里面有512个线程
  dim3 dimBlock(2,3);
  dim3 dimGrid(2,2);

  // 执行kernel
  matmult_v1<<<dimGrid, dimBlock>>>(ga, gb, gc, m,n,k);
  CUDA_LAST_ERROR();

  //cudaMemcpy ( void* dst, const void* src, size_t count, cudaMemcpyKind kind )
  cudaMemcpy(C, gc, m*n*sizeof(float), cudaMemcpyDeviceToHost);

  cudaFree(ga);
  cudaFree(gb);
  cudaFree(gc);

  SHOW_MAT(A,m,k);
  SHOW_MAT(B,k,n);
  SHOW_MAT(C,m,n);

  delete []A;
  delete []B;
  delete []C;

  return 0;
}