Name:          python3-hse
Version:       1.9
Release:       1%\{?dist}
Summary:       Python bindings for the Heterogeneous-Memory Storage Engine
License:       Apache-2.0
URL:           https://github.com/hse-project/hse
Source0:       hse-%{version}.tar.gz
BuildRequires: hse
BuildRequires: hse-devel
Requires:      hse

%description
Python bindings to HSE's C API. HSE is an embeddable key-value store designed
for SSDs based on NAND flash or persistent memory. HSE optimizes performance
and endurance by orchestrating data placement across DRAM and multiple classes
of SSDs or other solid-state storage. HSE is ideal for powering NoSQL,
Software-Defined Storage (SDS), High-Performance Computing (HPC), Big Data,
Internet of Things (IoT), and Artificial Intelligence (AI) solutions.

%prep
tar -xzf %{Source0}

%build
python setup.py build_ext

%install
python setup.py install

%check
python -c "import hse; print(hse.KVDB_VERSION_STRING)"
