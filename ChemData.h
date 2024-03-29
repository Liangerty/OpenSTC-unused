#pragma once

#include "Define.h"
#include "Parameter.h"
#include <map>
#include <string>
#include <vector>
#include "gxl_lib/Matrix.hpp"

namespace cfd {
struct Species {
#if MULTISPECIES == 1
  explicit Species(Parameter &parameter);

  void compute_cp(real temp, real *cp) const &;

  // The properties of the species. Some previously private derived variables will appear in the corresponding function classes.
  integer n_spec{1};  // number of species
  std::map<std::string, integer> elem_list; // element list
  std::map<std::string, integer> spec_list; // species list
  gxl::MatrixDyn<integer> elem_comp;  // the element composition of the species
  std::vector<real> mw; // the array of molecular weights
  // Thermodynamic properties
  std::vector<real> t_low, t_mid, t_high; // the array of thermodynamic sections
  gxl::MatrixDyn<real> high_temp_coeff, low_temp_coeff; // the cp/h/s polynomial coefficients
  // Transport properties
  std::vector<real> LJ_potent_inv;  // the inverse of the Lennard-Jones potential
  std::vector<real> vis_coeff;  // the coefficient to compute viscosity
  gxl::MatrixDyn<real> WjDivWi_to_One4th, sqrt_WiDivWjPl1Mul8; // Some constant value to compute partition functions
  // Temporary variables to compute transport properties, should not be accessed from other functions
  std::vector<real> x;
  std::vector<real> vis_spec;
  std::vector<real> lambda;
  gxl::MatrixDyn<real> partition_fun;


private:
  void set_nspec(integer n_sp, integer n_elem);

  void register_spec(const std::string &name, integer &index);

  void read_therm(Parameter &parameter);

  void read_tran(Parameter &parameter);
#endif
};

struct Reaction {
#if MULTISPECIES == 1
  explicit Reaction(Parameter &parameter);
#endif
};

struct ChemData {
#if MULTISPECIES == 1
  explicit ChemData(Parameter &parameter);

  Species spec;
  Reaction reac;
#endif
};
}
