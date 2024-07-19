# SlottedRandomAccess
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)


This repository implements the simulations tools for computing the Packet Loss Ratio (PLR) of slotted random access schemes.

The following schemes are currently supported:
- **CRDSA**: Contention Resolution Diversity Slotted ALOHA, introduced in [this 2007 IEEE paper](https://doi.org/10.1109/TWC.2007.348337)
- **MF-CRDSA**: Multi-Frequency Contention Resolution Diversity Slotted ALOHA, introduced in [this 2017 IEEE paper](https://doi.org/10.1109/TCOMM.2017.2696952)