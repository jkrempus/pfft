module pfft_{suffix};

import pfft_declarations_{suffix};

PfftTable{Suffix}* pfft_fft_table_allocate_{suffix}(size_t* nptr, size_t nlen);
