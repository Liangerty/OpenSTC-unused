#pragma once
#include "Define.h"
#include "Reconstruction.cuh"

namespace cfd {
struct DParameter;
struct DZone;

class InviscidScheme {
  Reconstruction* reconstruction;
public:
  __device__ explicit InviscidScheme(DParameter* param);

  __device__ virtual void compute_inviscid_flux(DZone *zone)=0;

  ~InviscidScheme()=default;
};

class AUSMP:public InviscidScheme{
  constexpr static real alpha{3/16.0}, beta{1/8.0};
public:
  __device__ explicit AUSMP(DParameter* param);

  __device__ void compute_inviscid_flux(DZone *zone) override;

  ~AUSMP()=default;
};
} // cfd
