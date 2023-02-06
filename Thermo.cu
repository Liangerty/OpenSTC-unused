#include "Thermo.cuh"
#include "DParameter.h"
#include "Constants.h"
#include "Field.h"

#if MULTISPECIES==1
__device__ void cfd::compute_enthalpy(real t, real *enthalpy, cfd::DParameter *param) {
  const real t2{t * t}, t3{t2 * t}, t4{t3 * t}, t5{t4 * t};
  for (int i = 0; i < param->n_spec; ++i) {
    if (t < param->t_low[i]) {
      const real tt = param->t_low[i];
      const real tt2 = tt * tt, tt3 = tt2 * tt, tt4 = tt3 * tt, tt5 = tt4 * tt;
      auto &coeff = param->low_temp_coeff;
      enthalpy[i] = coeff(i, 0) * tt + 0.5 * coeff(i, 1) * tt2 + coeff(i, 2) * tt3 / 3 + 0.25 * coeff(i, 3) * tt4 +
                    0.2 * coeff(i, 4) * tt5 + coeff(i, 5);
      const real cp = coeff(i, 0) + coeff(i, 1) * tt + coeff(i, 2) * tt2 + coeff(i, 3) * tt3 + coeff(i, 4) * tt4;
      enthalpy[i] += cp * (t - tt); // Do a linear interpolation for enthalpy
    } else {
      auto &coeff = t < param->t_mid[i] ? param->low_temp_coeff : param->high_temp_coeff;
      enthalpy[i] = coeff(i, 0) * t + 0.5 * coeff(i, 1) * t2 + coeff(i, 2) * t3 / 3 + 0.25 * coeff(i, 3) * t4 +
                    0.2 * coeff(i, 4) * t5 + coeff(i, 5);
    }
    enthalpy[i] *= cfd::R_u / param->mw[i];
  }
}

__device__ void cfd::compute_enthalpy_and_cp(real t, real *enthalpy, real *cp, cfd::DParameter *param) {
  const double t2{t * t}, t3{t2 * t}, t4{t3 * t}, t5{t4 * t};
  for (int i = 0; i < param->n_spec; ++i) {
    if (t < param->t_low[i]) {
      const double tt = param->t_low[i];
      const double tt2 = tt * tt, tt3 = tt2 * tt, tt4 = tt3 * tt, tt5 = tt4 * tt;
      auto &coeff = param->low_temp_coeff;
      enthalpy[i] = coeff(i, 0) * tt + 0.5 * coeff(i, 1) * tt2 + coeff(i, 2) * tt3 / 3 + 0.25 * coeff(i, 3) * tt4 +
                    0.2 * coeff(i, 4) * tt5 + coeff(i, 5);
      cp[i] = coeff(i, 0) + coeff(i, 1) * tt + coeff(i, 2) * tt2 + coeff(i, 3) * tt3 + coeff(i, 4) * tt4;
      enthalpy[i] += cp[i] * (t - tt); // Do a linear interpolation for enthalpy
    } else {
      auto &coeff = t < param->t_mid[i] ? param->low_temp_coeff : param->high_temp_coeff;
      enthalpy[i] = coeff(i, 0) * t + 0.5 * coeff(i, 1) * t2 + coeff(i, 2) * t3 / 3 + 0.25 * coeff(i, 3) * t4 +
                    0.2 * coeff(i, 4) * t5 + coeff(i, 5);
      cp[i] = coeff(i, 0) + coeff(i, 1) * t + coeff(i, 2) * t2 + coeff(i, 3) * t3 + coeff(i, 4) * t4;
    }
    enthalpy[i] *= R_u / param->mw[i];
    cp[i] *= R_u / param->mw[i];
  }
}

__device__ void cfd::compute_cp(real t, real *cp, cfd::DParameter *param) {
  const real t2{t * t}, t3{t2 * t}, t4{t3 * t};
  for (auto i = 0; i < param->n_spec; ++i) {
    if (t < param->t_low[i]) {
      const real tt = param->t_low[i];
      const real tt2 = tt * tt, tt3 = tt2 * tt, tt4 = tt3 * tt, tt5 = tt4 * tt;
      auto &coeff = param->low_temp_coeff;
      cp[i] = coeff(i, 0) + coeff(i, 1) * tt + coeff(i, 2) * tt2 + coeff(i, 3) * tt3 + coeff(i, 4) * tt4;
    } else {
      auto &coeff = t < param->t_mid[i] ? param->low_temp_coeff : param->high_temp_coeff;
      cp[i] = coeff(i, 0) + coeff(i, 1) * t + coeff(i, 2) * t2 + coeff(i, 3) * t3 + coeff(i, 4) * t4;
    }
    cp[i] *= R_u / param->mw[i];
  }
}
#endif

__device__ void cfd::compute_total_energy(integer i, integer j, integer k, cfd::DZone *zone, DParameter *param) {
  auto &bv = zone->bv;
  auto &vel = zone->vel;
  auto &cv = zone->cv;

  vel(i, j, k) = bv(i, j, k, 1) * bv(i, j, k, 1) + bv(i, j, k, 2) * bv(i, j, k, 2) + bv(i, j, k, 3) * bv(i, j, k, 3);
  cv(i, j, k, 4) = 0.5 * bv(i, j, k, 0) * vel(i, j, k);
#if MULTISPECIES == 1
  real *enthalpy = new real[zone->n_spec];
  compute_enthalpy(bv(i, j, k, 5), enthalpy, param);
  // Add species enthalpy together up to kinetic energy to get total enthalpy
  for (auto l = 0; l < zone->n_spec; l++) {
    cv(i, j, k, 4) += enthalpy[l] * cv(i, j, k, 5 + l);
  }
  cv(i, j, k, 4) -= bv(i, j, k, 4);  // (\rho e =\rho h - p)
#else
  cv(i, j, k, 4) += bv(i, j, k, 4) / (cfd::gamma_air - 1);
#endif // MULTISPECIES==1
  vel(i, j, k) = sqrt(vel(i, j, k));
}
