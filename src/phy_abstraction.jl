# This is the polyonmial for approximating the packet error rate of a 100 bit word with rate 1/3, only for ebno values above -1.8 dB. Used for CRDSA/MF-CRDSA papers
const _PLR_cr13_100b_Odr3_polynomial = Polynomial([
-0.215782058480603,
-0.374234466906317,
-0.222858550651536,
-0.0507630949758589,
-0.00197105590755756,
0.00436433391082898,
0.00136041159250727,
-0.000397502358373164,
])

"""
    PLR_cr13(EbN0)
Compute the packet error rate as a function of the energy per bit divided by the
noise power spectral density (`EbN0`), expressed as plain number (i.e. not in
dB)

It internally uses the polynomial defined in `_PLR_cr13_100b_Odr3_polynomial` representing the PHY abstraction for a 100bit word with a rate of 1/3
"""
function PLR_cr13(ebno)
	# We translate the inpu in dB, as we are assuming it is in linear
	ebno_db = 10log10(ebno)
	plr = ebno_db >= -1.8 ? 10^_PLR_cr13_100b_Odr3_polynomial(ebno_db) : 1.0
    return plr
end

# This is the polyonmial for approximating the packet error rate of a 100 bit word with rate 1/2, only for ebno values between -1 and 3 dB. Used for CRDSA/MF-CRDSA papers
const _PLR_cr12_100b_Odr3_polynomial = Polynomial([
-0.109622088831103,
-0.243226557211830,
-0.185414870643508,
0.043439484192318,
0.022671110316843,
-0.137378346146966,
0.044482830864468,
0.056115084121172,
-0.044564032105053,
0.011682817565128,
-0.001061188368566,
])

"""
    PLR_cr12(EbN0)
Compute the packet error rate as a function of the energy per bit divided by the
noise power spectral density (`EbN0`), expressed as plain number (i.e. not in
dB)

It internally uses the polynomial defined in `_PLR_cr12_100b_Odr3_polynomial` representing the PHY abstraction for a 100bit word with a rate of 1/2
"""
function PLR_cr12(ebno)
	# We translate the inpu in dB, as we are assuming it is in linear
	ebno_db = 10log10(ebno)
    ebno_db <= -1 && return 1.0
	ebno_db <= 3 && return 10^_PLR_cr12_100b_Odr3_polynomial(ebno_db) # Use the 10 degree polynomial approximation
    # If we get here we use the last simple polynomial
    return 10^(-1.209949465790318 * ebno_db + 0.805939656426635)
end

function default_plr_function(rate)
    rate ≈ 1/3 && return PLR_cr13
    rate ≈ 1/2 && return PLR_cr12
    error("The provided rate does not have a corresponding default packet loss rate function")
end