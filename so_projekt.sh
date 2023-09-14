#!/bin/bash

# Sprawdzamy liczbe argumentow
if [ $# -eq 0 ]; then
    echo "Blad: Brak argumentow. Poprawne uzycie: $0 <KAT_BAZOWY> <nazwa_pliku_danych1> <nazwa_pliku_danych2>...<nazwa_pliku_danychN>" >&2
    exit 1
elif [ $# -eq 1 ]; then
    echo "Blad: Podano tylko jeden argument. Poprawne uzycie: $0 <KAT_BAZOWY> <nazwa_pliku_danych1> <nazwa_pliku_danych2>...<nazwa_pliku_danychN>" >&2
    exit 2
fi

KAT_BAZOWY="$1"

# Sprawdzamy czy katalog bazowy istnieje 
if [ ! -d "$KAT_BAZOWY" ]; then  
    if ! mkdir -p "$KAT_BAZOWY"; then 
        echo "Blad: Nie mozna utworzyc katalogu bazowego '$KAT_BAZOWY'. Brak odpowiednich uprawnien lub bledna sciezka." >&2
        exit 4
    fi
fi

# Sprawdzamy czy pliki istnieja
for ((i=2; i<=$#; i++)); do
    plik="${!i}"   
    if [ ! -f "$plik" ]; then   
        echo "Blad: Plik danych '$plik' nie istnieje lub nie masz dostepu do tego pliku." >&2
        exit 3
    fi
done

#0 START 

start=$(date +%s%3N)

PID=$$

wiersz_polecen="$0 $@"

#1 START 

for ((i=2; i<=$#; i++)); do
	plik="${!i}"
	cat "$plik" | awk -F'","|,' -v KAT_BAZOWY="$KAT_BAZOWY" '{
	system("mkdir -p \"" KAT_BAZOWY "\"/"$3"/"$4);    
	system("chmod 750 \"" KAT_BAZOWY "\"/"$3"/"$4)}'
done

#1 STOP 

#2, 3 START 

for (( i=2; i<=$#; i++)) do
plik="${!i}"
cat "$plik" | awk -F '","|,|",|,"' -v KAT_BAZOWY="$KAT_BAZOWY" '{ 

if ($7 != "8") {
    system("echo "$0" >> \"" KAT_BAZOWY "\"/"$3"/"$4"/"$5".csv");
    system("chmod 640 \"" KAT_BAZOWY "\"/"$3"/"$4"/"$5".csv")
} else {
    system("echo "$0" >> \"" KAT_BAZOWY "\"/"$3"."$4".errors");
    system("chmod 640 \"" KAT_BAZOWY "\"/"$3"."$4".errors")}
}'

done

#2, 3 STOP 

#4 START 

mkdir -p "$KAT_BAZOWY/LINKS"

MIN=""
MIN_PLIK=""

MAX=""
MAX_PLIK=""

for rok in "$KAT_BAZOWY"/*; do
    if [[ "$rok" == "$KAT_BAZOWY/LINKS" ]]; then
    continue 

    elif [[ -f "$rok" ]]; then 
    continue
    fi

	for miesiac in "$rok"/*; do
    	for dzien in "$miesiac"/*.csv; do
        	opady=$(cat "$dzien" | awk -F '","|,|",|,"' '{print $6}')
            suma_opad=0
            for opad in $opady; do
                suma_opad=$(echo "$suma_opad+$opad" | bc) 
            done
        if [ -z "$MIN" ] || (( $(echo "$suma_opad<$MIN" | bc) )); then 
            MIN="$suma_opad"
            MIN_PLIK="$dzien"
        fi	

        if [ -z "$MAX" ] || (( $(echo "$suma_opad>$MAX" | bc) )); then 
            MAX="$suma_opad"
            MAX_PLIK="$dzien"
        fi	

        done
    done
done

#Tworzymy sciezke, ktora wskazuje jak odniesc sie do pliku

MIN_PLIK=$(realpath --relative-to="$KAT_BAZOWY/LINKS" "$MIN_PLIK")
MAX_PLIK=$(realpath --relative-to="$KAT_BAZOWY/LINKS" "$MAX_PLIK")


ln -sf "$MIN_PLIK" "$KAT_BAZOWY/LINKS/MIN_OPAD"
ln -sf "$MAX_PLIK" "$KAT_BAZOWY/LINKS/MAX_OPAD"

#4 STOP 

koniec=$(date +%s%3N) 

czas=$((koniec-start))

format="$PID,$PPID,$czas,$wiersz_polecen"

echo "$format" >> "$KAT_BAZOWY"/out.log

chmod 640 "$KAT_BAZOWY"/out.log

#0 STOP 


