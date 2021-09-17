# saber-chip
Source files of a SABER cryptocore that was taped out in September 2021. This is a collaborative work between TalTech and TU Graz.

The name of the top module is wrapper_top. This is mostly a serialized interface that we created to reduce the pin count on the fabricated chip.

The top module contains two instantiations, i.e., (i) ComputeCore3, and (ii) shift_registers. The ComputeCore3 module consists of required building-blocks of SABER and the memory instances. It is largely based on the work of https://github.com/sujoyetc/SABER_HW. The shift_registers are also meant for external communication/serialization/debug. 

To execute associated KEM operations (i.e., KeyGen, Encapsulation and decapsulation), the corresponding test files are (i) tb_kem_keygen, (ii) tb_kem_enc_new, and (iii) tb_kem_dec_cca.

More details are available from: https://eprint.iacr.org/2021/1202
