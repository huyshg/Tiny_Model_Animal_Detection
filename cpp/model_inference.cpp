#include "inference.hpp"

#include <filesystem>
#include <iostream>
#include <stdexcept>

int main() {
    try {
        std::filesystem::path project_root = "..";
        return run_model_inference(project_root);
    } catch (const std::exception& ex) {
        std::cerr << "ERROR: " << ex.what() << "\n";
        return 1;
    }
}
