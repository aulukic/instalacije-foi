Upute za Pokretanje

Otvorite terminal na vašem svježe instaliranom Linux Mintu i kopirajte cijeli sljedeći blok naredbi odjednom, a zatim ga zalijepite u terminal i pritisnite Enter.

# === BLOK NAREDBI ZA KOPIRANJE ===

# 1. Postavljanje varijabli
SKRIPT_URL="https://raw.githubusercontent.com/aulukic/instalacije-foi/refs/heads/main/instalacije.sh"
SKRIPT_NAZIV="konacna_instalacija.sh"
LOG_DATOTEKA="instalacija_log_$(date +%Y-%m-%d_%H-%M-%S).txt"

# 2. Preuzimanje najnovije verzije skripte
echo "--- Preuzimam skriptu s GitHub-a... ---"
wget -O "$SKRIPT_NAZIV" "$SKRIPT_URL"

# 3. Davanje izvršnih ovlasti
chmod +x "$SKRIPT_NAZIV"

# 4. Rješavanje problema s Windows linijskim završecima (ako postoji)
# Ova naredba je tu za svaki slučaj. Ako ste ispravno kopirali skriptu, neće biti potrebna.
if command -v dos2unix &> /dev/null; then
    dos2unix "$SKRIPT_NAZIV"
else
    sudo apt-get install -y dos2unix
    dos2unix "$SKRIPT_NAZIV"
fi

# 5. Pokretanje skripte uz spremanje ispisa u log datoteku
echo "--- Pokrećem instalacijsku skriptu. Sav ispis bit će spremljen u: $LOG_DATOTEKA ---"
./"$SKRIPT_NAZIV" 2>&1 | tee "$LOG_DATOTEKA"

# === KRAJ BLOKA ===
