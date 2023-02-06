﻿#pragma once
#include <string>
#include <fstream>
#include <sstream>

namespace gxl {
// Some string functions
const std::string whiteSpace=" \n\t\r\f\v";

enum class Case { lower, upper, keep };

std::istream& getline(std::ifstream& file, std::string& input, Case u_l=Case::keep);

void to_stringstream(const std::string& str, std::istringstream& line);

std::istream& getline_to_stream(std::ifstream& file, std::string& input, std::istringstream& line, Case u_l=Case::keep);

void trim_left(std::string& string);

void read_until(std::ifstream& file, std::string& input, std::string&& to_find, Case u_l=Case::keep);

std::string to_upper(std::string& str);
}
