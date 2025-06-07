/* ===START=== */
starter_game :-
    write('Selamat datang di dunia Pokemon!'), nl,
    write('Siapa nama kamu? '),
    read(Nama),
    asserta(pemain(Nama)),
    pilih_starter(Nama),
    nl, format('Selamat bermain, ~w!', [Nama]), nl,
    tampilkan_starter(Nama).

tampilkan_pilihan_starter :-
    write('Silakan pilih dua Pokemon starter dari pilihan berikut:'), nl,
    starter_tersedia(1, P1), format('1. ~w~n', [P1]),
    starter_tersedia(2, P2), format('2. ~w~n', [P2]),
    starter_tersedia(3, P3), format('3. ~w~n', [P3]).

valid_angka(Input) :- member(Input, [1, 2, 3]).

/* Membaca input yang valid */
baca_input_starter(Index) :-
    read(Input),
    ( valid_angka(Input) ->
        Index = Input
    ;
        write('Pilihan tidak valid. Masukkan angka antara 1-3:'), nl,
        baca_input_starter(Index)
    ).

/* Memilih dua starter yang valid dan berbeda */
pilih_starter(Nama) :-
    tampilkan_pilihan_starter,
    write('Masukkan nomor starter pertama (1-3): '),
    baca_input_starter(I1),
    write('Masukkan nomor starter kedua (1-3, berbeda dari pertama): '),
    baca_input_starter(I2),
    ( I1 =:= I2 ->
        write('Tidak boleh memilih Pokemon yang sama. Ulangi pilihan.'), nl,
        pilih_starter(Nama)
    ;
        starter_tersedia(I1, Poke1),
        set_status_awal(Poke1, 1, HPnow1, HPfull1, ATKnow1, ATKfull1, DEFnow1, DEFfull1),
        starter_tersedia(I2, Poke2),
        set_status_awal(Poke2, 1, HPnow2, HPfull2, ATKnow2, ATKfull2, DEFnow2, DEFfull2),
        asserta(party(Nama, Poke1, 1, HPnow1, HPfull1, ATKnow1, ATKfull1, DEFnow1, DEFfull1, 0)),
        asserta(party(Nama, Poke2, 1, HPnow2, HPfull2, ATKnow2, ATKfull2, DEFnow2, DEFfull2, 0))
    ).

/* Menampilkan Pokémon yang telah dipilih */
tampilkan_starter(Nama) :-
    write('Pokemon starter kamu adalah:'), nl,
    forall(party(Nama, P, _, _HPnow, _HPfull, _ATKnow, _ATKfull, _DEFnow, _DEFfull, _),
        format('- ~w~n', [P])
    ).


show_position :-
    pemain(Nama),
    posisi_pemain(Nama, RX, RY),
    RY_flipped is 9 - RY,
    format('Posisi pemain saat ini: (~w, ~w)~n', [RX, RY_flipped]).

/* === Party === */
show_party :-
    pemain(Nama),
    write('Daftar Pokemon di party milik '), write(Nama), write(':'), nl,
    findall((Pokemon, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP), party(Nama, Pokemon, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP), Daftar),
    show_party_list(Daftar, 1).

show_party_list([], _).
show_party_list([(Pokemon, Level, HPnow, _HPfullSaved, ATKnow, _ATKfullSaved, DEFnow, _DEFfullSaved, EXP)|T], Index) :-
    nama_dasar(Pokemon, BasePokemon),
    pokemon(BasePokemon, _, _, BaseHP, BaseATK, BaseDEF, _, _, _, _),
    HPfull is BaseHP + (Level - 1) * 2,
    ATKfull is BaseATK + (Level - 1) * 1,
    DEFfull is BaseDEF + (Level - 1) * 1,
    format('~d. ~w (Level ~d)~n', [Index, Pokemon, Level]),
    format('    HP  : ~d (~d)~n', [HPnow, HPfull]),
    format('    ATK : ~d (~d)~n', [ATKnow, ATKfull]),
    format('    DEF : ~d (~d)~n', [DEFnow, DEFfull]),
    write('     EXP : '), write(EXP), nl,
    NextIndex is Index + 1,
    show_party_list(T, NextIndex).

/* Mengambil nama dasar dari nama Pokémon seperti 'charmeleon(1)' → 'charmeleon' */
nama_dasar(NamaLabel, Dasar) :-
    atom_codes(NamaLabel, Codes),
    ( append(D, [40|_], Codes) -> % 40 = '('
        atom_codes(Dasar, D)
    ;
        Dasar = NamaLabel
    ).

/* === TAS === */
init_tas(Pemain) :-
    retractall(isi_tas(Pemain,_,_)),
    forall(between(1,20,I), asserta(isi_tas(Pemain, I, item_pokeball(kosong)))),
    forall(between(21,40,I), asserta(isi_tas(Pemain, I, kosong))).

jumlah_pokeball_kosong(Pemain, Jumlah) :-
    findall(1, isi_tas(Pemain, _, item_pokeball(kosong)), L),
    length(L, Jumlah).

show_tas_non_empty(Pemain, DaftarPokemonTas) :-
    findall((Idx, Nama, Poke, Level), (isi_tas(Pemain, Idx, item_pokeball(pokemon_tas(Nama, Poke, Level, _, _, _, _, _, _, _)))), DaftarPokemonTas),
    write('Pokemon di tas (pokeball yang berisi):'), nl,
    tampilkan_daftar_pokemon(DaftarPokemonTas).


tampilkan_daftar_pokemon([]).
tampilkan_daftar_pokemon([(Idx, Nama, Poke, Level)|T]) :-
    format('Slot ~w: ~w (Nama: ~w, Lv: ~w)~n', [Idx, Poke, Nama, Level]),
    tampilkan_daftar_pokemon(T).

/* ===TAMBAH PARTY=== */
tambah_party :-
    pemain(Pemain),
    show_tas_non_empty(Pemain, DaftarPokemonTas),
    ( DaftarPokemonTas = [] ->
        write('Tas pokeball kosong, tidak ada pokemon untuk ditambahkan.'), nl
    ;
        write('Pilih nomor slot pokeball untuk ditambahkan ke party (atau ketik quit untuk batal): '),
        baca_pilihan_slot(Pemain, DaftarPokemonTas)
    ), show_party.


baca_pilihan_slot(Pemain, DaftarPokemonTas) :-
    read(Input),
    ( Input == quit ->
        write('Batal menambah party.'), nl
    ; integer(Input) ->
        (
            % Hitung jumlah pokemon di party sekarang
            findall(_, party(Pemain, _, _, _, _, _, _, _, _, _), PartyList),
            length(PartyList, CountParty),
            ( CountParty >= 4 ->
                write('Party sudah penuh (maksimal 4 Pokémon).'), nl
            ;
                ( member((Input, Nama, Poke, Level), DaftarPokemonTas),
                  isi_tas(Pemain, Input, item_pokeball(pokemon_tas(Nama, Poke, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP))) ->

                    findall(PNama, party(Pemain, PNama, _, _, _, _, _, _, _, _), NamaList),
                    count_same_name(Poke, NamaList, Count),

                    ( Count = 0 ->
                        FinalName = Poke
                    ;
                        number_codes(Count, CountCodes),
                        atom_codes(Poke, PokeCodes),
                        append(PokeCodes, [40|CountCodes], Temp),   % 40 = '('
                        append(Temp, [41], FinalCodes),             % 41 = ')'
                        atom_codes(FinalName, FinalCodes)
                    ),

                    asserta(party(Pemain, FinalName, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP)),
                    retract(isi_tas(Pemain, Input, item_pokeball(pokemon_tas(Nama, Poke, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP)))),
                    asserta(isi_tas(Pemain, Input, item_pokeball(kosong))),
                    write('Pokemon berhasil ditambahkan ke party sebagai '), write(FinalName), write('.'), nl

                ;
                    write('Slot tidak valid atau pokeball kosong.'), nl,
                    tambah_party
                )
            )
        )
    ;
        write('Input tidak valid, ketik nomor slot atau quit.'), nl,
        tambah_party
    ).

/* Menghitung jumlah elemen dalam list yang namanya memiliki awalan sama */
count_same_name(_, [], 0).
count_same_name(Poke, [H|T], Count) :-
    ( same_name_base(Poke, H) ->
        count_same_name(Poke, T, Count1),
        Count is Count1 + 1
    ;
        count_same_name(Poke, T, Count)
    ).

/* Cek apakah dua nama memiliki nama dasar yang sama */
same_name_base(Base, Nama) :-
    atom_codes(Base, BaseCodes),
    atom_codes(Nama, NamaCodes),
    is_prefix(BaseCodes, NamaCodes).

/* is_prefix(Xs, Ys) benar jika Xs adalah prefix dari Ys */
is_prefix([], _).
is_prefix([H|T1], [H|T2]) :-
    is_prefix(T1, T2).

/* ===HAPUS PARTY=== */
hapus_party :-
    pemain(Pemain),
    findall((N, Poke), party_index(Pemain, N, Poke), DaftarParty),
    ( DaftarParty = [] ->
        write('Party kosong, tidak ada Pokemon untuk dihapus.'), nl
    ;
        tampilkan_party_index(DaftarParty),
        write('Pilih nomor Pokemon di party yang ingin dihapus (atau ketik quit untuk batal): '),
        baca_hapus_party(Pemain, DaftarParty)
    ).

baca_hapus_party(Pemain, DaftarParty) :-
    read(Input),
    ( Input == quit ->
        write('Batal menghapus Pokemon dari party.'), nl
    ; integer(Input) ->
        ( member((Input, Pokemon), DaftarParty),
          party(Pemain, Pokemon, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP) ->
            retract(party(Pemain, Pokemon, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP)),

            nama_dasar(Pokemon, NamaDasar),

            ( isi_tas(Pemain, Slot, item_pokeball(kosong)) ->
                retract(isi_tas(Pemain, Slot, item_pokeball(kosong))),
                asserta(isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(NamaDasar, NamaDasar, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, EXP)))),
                format('Pokemon ~w Lv.~w dimasukkan ke pokeball slot ~w di tas.~n', [NamaDasar, Level, Slot])
            ;
                write('Tas penuh, tidak ada pokeball kosong untuk menyimpan Pokemon.'), nl,
                format('Pokemon ~w Lv.~w hilang karena tidak ada tempat di tas.~n', [NamaDasar, Level])
            ),
            write('Pokemon berhasil dihapus dari party.'), nl
        ;
            write('Nomor tidak valid.'), nl,
            hapus_party
        )
    ;
        write('Input tidak valid, ketik nomor atau quit.'), nl,
        hapus_party
    ).


/* ===TUKAR PARTY=== */
tukar_party :-
    pemain(Pemain),
    findall(Poke, party(Pemain, Poke, _Lv, _Hn, _Hf, _An, _Af, _Dn, _Df, _), Daftar),
    length(Daftar, Len),
    ( Len < 2 ->
        write('Party harus punya minimal 2 Pokemon untuk ditukar.'), nl
    ;
        tampilkan_party_index_with_level(Pemain),
        write('Masukkan nomor Pokemon pertama yang ingin ditukar (atau ketik quit untuk batal): '),
        read(N1),
        ( N1 == quit ->
            write('Batal tukar party.'), nl, !
        ;
            write('Masukkan nomor Pokemon kedua yang ingin ditukar: '),
            read(N2),
            ( N2 == quit ->
                write('Batal tukar party.'), nl, !
            ;
                tukar_party_pos(Pemain, N1, N2)
            )
        )
    ).


tukar_party_pos(_, quit, _) :- write('Batal tukar party.'), nl.
tukar_party_pos(_, _, quit) :- write('Batal tukar party.'), nl.
tukar_party_pos(Pemain, N1, N2) :-
    integer(N1), integer(N2),
    N1 > 0, N2 > 0,
    findall(Poke, party(Pemain, Poke, _Lv, _Hn, _Hf, _An, _Af, _Dn, _Df, _), Daftar),
    length(Daftar, Len),
    N1 =< Len, N2 =< Len,
    ( N1 == N2 ->
        write('Tidak ada yang perlu ditukar karena memilih posisi yang sama.'), nl,
        tukar_party
    ;
        nth1(N1, Daftar, Poke1),
        nth1(N2, Daftar, Poke2),
        party(Pemain, Poke1, L1, HN1, HF1, AN1, AF1, DN1, DF1, EXP1),
        party(Pemain, Poke2, L2, HN2, HF2, AN2, AF2, DN2, DF2, EXP2),
        retract(party(Pemain, Poke1, L1, HN1, HF1, AN1, AF1, DN1, DF1, EXP1)),
        retract(party(Pemain, Poke2, L2, HN2, HF2, AN2, AF2, DN2, DF2, EXP2)),
        asserta(party(Pemain, Poke2, L2, HN2, HF2, AN2, AF2, DN2, DF2, EXP2)),
        asserta(party(Pemain, Poke1, L1, HN1, HF1, AN1, AF1, DN1, DF1, EXP2)),
        write('Berhasil menukar posisi Pokemon di party.'), nl,
        tukar_party
    ).
tukar_party_pos(_, _, _) :-
    write('Nomor posisi tidak valid.'), nl,
    tukar_party.

    
tampilkan_party_index_with_level(Pemain) :-
    findall((N, Poke, L, HN, HF, AN, AF, DN, DF, EXP),
        (party_index(Pemain, N, Poke),
         party(Pemain, Poke, L, HN, HF, AN, AF, DN, DF, EXP)),
        List),
    tampilkan_party_level(List).

tampilkan_party_level([]).
tampilkan_party_level([(N, P, L, _Hn, _Hf, _An, _Af, _Dn, _Df, _)|T]) :-
    format('~w. ~w (Level: ~w)~n', [N, P, L]),
    tampilkan_party_level(T).


/* helper untuk party dengan indeks */
party_index(Pemain, Index, Pokemon) :-
    findall(Pokemon, party(Pemain, Pokemon, _Level, _HPnow, _HPfull, _ATKnow, _ATKfull, _DEFnow, _DEFfull, _), List),
    nth1(Index, List, Pokemon).

/* helper untuk menampilkan party dengan nomor indeks */
tampilkan_party_index([]).
tampilkan_party_index([(N, P)|T]) :-
    format('~w. ~w~n', [N, P]),
    tampilkan_party_index(T).