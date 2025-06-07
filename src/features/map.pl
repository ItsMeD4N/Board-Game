:- discontiguous(apply_skill_effect/2).

/* === MAP === */
/* Menampilkan peta dengan posisi pemain dan pokemon tersembunyi */
show_map :-
    move_count(Moves),
    format('Total moves: ~w / 20~n', [Moves]),
    pemain(Nama),
    posisi_pemain(Nama, PX, PY),
    lebar_peta(Lebar),
    tinggi_peta(Tinggi),
    forall(between(1, Tinggi, Y),
        (
            cetak_batas_kotak(Lebar),
            write('|'),
            forall(between(1, Lebar, X),
                (
                    (X =:= PX, Y =:= PY) -> write(' P |')
                    ; (pokemon_bersembunyi(X, Y, _), tile(X, Y, Tile), Tile = '.') -> write(' C |')
                    ; (tile(X, Y, Tile), Tile = '#') -> write(' # |')
                    ; write('   |')
                )
            ),
            nl
        )
    ),
    cetak_batas_kotak(Lebar), nl,
    show_position.

/* Cetak baris batas kotak seperti: +---+---+---+... */
cetak_batas_kotak(Lebar) :-
    forall(between(1, Lebar, _), write('+---')),
    write('+'), nl.

/* Ukuran peta */
lebar_peta(8).
tinggi_peta(8).


/* Menampilkan isi tas pemain */
show_inventori :-
    pemain(Nama),
    format('Isi tas milik ~w:~n', [Nama]),
    tampilkan_baris(Nama, 1).

tampilkan_baris(_, Slot) :-
    Slot > 40, !.

tampilkan_baris(Nama, SlotAwal) :-
    SlotAkhir is min(SlotAwal + 1, 40),
    tampilkan_slot_range(Nama, SlotAwal, SlotAkhir),
    nl,
    SlotBerikutnya is SlotAkhir + 1,
    tampilkan_baris(Nama, SlotBerikutnya).

tampilkan_slot_range(Nama, Slot, Slot) :-
    isi_tas(Nama, Slot, Item),
    write('['), write(Slot), write(':'),
    tulis_item(Item),
    write(']').

tampilkan_slot_range(Nama, SlotAwal, SlotAkhir) :-
    SlotAwal < SlotAkhir,
    isi_tas(Nama, SlotAwal, Item),
    write('['), write(SlotAwal), write(':'),
    tulis_item(Item),
    write('] '),
    NextSlot is SlotAwal + 1,
    tampilkan_slot_range(Nama, NextSlot, SlotAkhir).

tulis_item(kosong) :- write('-').
tulis_item(item_pokeball(kosong)) :- write('pokeball(-)').
tulis_item(item_pokeball(pokemon_tas(_Nama, Pokemon, Level, _HPnow, _HPfull, _ATKnow, _ATKfull, _DEFnow, _DEFfull, _))) :-
    write('pokeball('), write(Pokemon), write(' Lv.'), write(Level), write(')').
tulis_item(item_pokeball(Pokemon)) :-
    write('pokeball('), write(Pokemon), write(')').
tulis_item(Item) :-
    term_to_atom(Item, Atom),
    write(Atom).

/* Menginisialisasi tile peta 8x8 secara acak */
init_map :-
    forall((between(1,8,Y), between(1,8,X)), 
        (
            random(R0),
            R is round(R0*100)+1,
            (R =< 60 -> Tipe = '#' ; Tipe = '.'),
            asserta(tile(X,Y,Tipe))
        )
    ).

/* Validasi bahwa peta memiliki setidaknya satu tile '#' */
peta_valid :-
    findall((X,Y), tile(X,Y,'#'), GrassTiles),
    GrassTiles \= [].

/* Mengacak posisi pemain di peta yang bisa dilewati */
acak_posisi_pemain :-
    pemain(Nama),
    repeat,
    random(RX0), RX is floor(RX0 * 8) + 1,
    random(RY0), RY is floor(RY0 * 8) + 1,
    tile(RX, RY, _),
    bisa_dilewati(RX, RY),
    \+ pokemon_bersembunyi(RX, RY, _), 
    retractall(posisi_pemain(_,_,_)),
    asserta(posisi_pemain(Nama, RX, RY)),
    !.

/* Menyebarkan semua jenis pokemon sesuai jumlah dan rarity */
spawn_semua_pokemon :-
    pemain(Nama),
    retractall(pokemon_bersembunyi(_, _, _)),
    posisi_pemain(Nama, PX, PY),

    TotalPokemon is 32,
    TotalLegendary is 1,
    Sisa is TotalPokemon - TotalLegendary,

    CommonRatio is 0.60,
    RareRatio is 0.25,
    EpicRatio is 0.15,

    BaseCommon is floor(Sisa * CommonRatio),
    BaseRare is floor(Sisa * RareRatio),
    BaseEpic is floor(Sisa * EpicRatio),
    Assigned is BaseCommon + BaseRare + BaseEpic,
    Remain is Sisa - Assigned,

    FC is Sisa * CommonRatio - BaseCommon,
    FR is Sisa * RareRatio - BaseRare,
    FE is Sisa * EpicRatio - BaseEpic,

    RawList = [(common, BaseCommon, FC), (rare, BaseRare, FR), (epic, BaseEpic, FE)],
    manual_sort_by_fraction(RawList, Sorted),
    distribute_remain(Remain, Sorted, FinalList),
    member((common, TotalCommon, _), FinalList),
    member((rare, TotalRare, _), FinalList),
    member((epic, TotalEpic, _), FinalList),

    spawn_legendary_pokemon(PX, PY),
    spawn_pokemon_by_rarity(epic, TotalEpic, PX, PY),
    spawn_pokemon_by_rarity(rare, TotalRare, PX, PY),
    spawn_common_pokemon(TotalCommon, PX, PY),
    
    findall(_, pokemon_bersembunyi(_, _, _), SpawnedList),
    length(SpawnedList, LenSpawned),
    format("Total Pokemon spawned: ~w (Common: ~w, Rare: ~w, Epic: ~w, Legendary: 1)\n",
        [LenSpawned, TotalCommon, TotalRare, TotalEpic]),
    !.

/* Menyebarkan satu pokemon legendary pada tile '#' */
spawn_legendary_pokemon(_, _) :-
    findall((X,Y), (tile(X,Y,'#'), \+ posisi_pemain(_,X,Y), \+ pokemon_bersembunyi(X,Y,_)), GrassTiles),
    GrassTiles \= [],
    random_member((LX, LY), GrassTiles),
    findall(P, pokemon(P, legendary, _, _, _, _, _, _, _, _), Legendaries),
    random_member(_Pokemon, Legendaries),
    random(1, 10, Level),
    asserta(pokemon_bersembunyi(LX, LY, level_pokemon(_Pokemon, Level))).

/* Menyebarkan pokemon berdasarkan rarity pada tile '#' */
spawn_pokemon_by_rarity(_, 0, _, _) :- !.
spawn_pokemon_by_rarity(Rarity, Count, PX, PY) :-
    Count > 0,
    findall(P, pokemon(P, Rarity, _, _, _, _, _, _, _, _), List),
    findall((X,Y), (tile(X,Y,'#'), \+ pokemon_bersembunyi(X,Y,_), \+ posisi_pemain(_,X,Y)), ValidTiles),
    ValidTiles \= [],
    random_member((X,Y), ValidTiles),
    random_member(_Pokemon, List),
    random(1, 10, Level),
    asserta(pokemon_bersembunyi(X, Y, level_pokemon(_Pokemon, Level))),
    NewCount is Count - 1,
    spawn_pokemon_by_rarity(Rarity, NewCount, PX, PY).

/* Menyebarkan pokemon common di tile '#' atau '.' */
spawn_common_pokemon(0, _, _) :- !.

spawn_common_pokemon(Count, PX, PY) :-
    Count > 0,
    findall(P, pokemon_common(P), BasicCommons),
    findall(P, pokemon_evolved(P), EvolvedCommons),
    findall((X,Y), 
        (tile(X,Y,T), (T = '#' ; T = '.'), 
         \+ pokemon_bersembunyi(X,Y,_), 
         \+ posisi_pemain(_,X,Y)), 
        ValidTiles),
    ValidTiles \= [],

    random_member((X,Y), ValidTiles),
    
    random(1, 101, Chance),  
    (
        Chance =< 90 -> 
            random_member(Pokemon, BasicCommons),
            random(1, 9, Level)
        ;
        random_member(Pokemon, EvolvedCommons),
        Level = 10
    ),

    asserta(pokemon_bersembunyi(X, Y, level_pokemon(Pokemon, Level))),
    NewCount is Count - 1,
    spawn_common_pokemon(NewCount, PX, PY).

/* Mengurutkan tuple berdasarkan komponen ketiga secara descending */
manual_sort_by_fraction(List, Sorted) :-
    maplist(third_key_tuple, List, Keyed), 
    keysort(Keyed, SortedKeyedAsc),
    reverse(SortedKeyedAsc, SortedKeyedDesc),
    pairs_values(SortedKeyedDesc, Sorted).

/* Mengambil value dari pasangan key-value */
pairs_values([], []).
pairs_values([_-V | T], [V | VT]) :-
    pairs_values(T, VT).

/* Membuat pasangan key-value dari tuple */
third_key_tuple((R,B,F), F-(R,B,F)).

/* Membagi jumlah remain ke tuple yang tersedia */
distribute_remain(0, L, L).
distribute_remain(N, [(R,B,F)|Rest], [(R,NewB,F)|NewRest]) :-
    N > 0,
    NewB is B + 1,
    N1 is N - 1,
    distribute_remain(N1, Rest, NewRest).


/* === POKEMON COMMON === */
bisa_dilewati(X,Y) :-
    tile(X,Y,T),
    (T = '#' ; T = '.').


/* === MOVE === */
move(Direction) :-
    pemain(Nama),
    posisi_pemain(Nama, X, Y),
    (
        Direction = up -> Y1 is Y - 1, X1 is X;
        Direction = down -> Y1 is Y + 1, X1 is X;
        Direction = left -> X1 is X - 1, Y1 is Y;
        Direction = right -> X1 is X + 1, Y1 is Y;
        write('Arah tidak valid.'), nl, fail
    ),
    (
        X1 >= 1, X1 =< 8, Y1 >= 1, Y1 =< 8 ->
            (
                bisa_dilewati(X1, Y1) ->
                    add_move,
                    add_level,
                    retract(posisi_pemain(Nama, X, Y)),
                    asserta(posisi_pemain(Nama, X1, Y1)),
                    format('Berhasil bergerak ke (~w,~w).~n', [X1, Y1]),
                    heal_pokemon,
                    (pokemon_bersembunyi(X1, Y1, level_pokemon(Pokemon, Level)) ->
                        level_count(N),
                        NewLevel is Level + N,
                        show_map,
                        format('Ada Pokemon ~w level ~w di sini!~n', [Pokemon, NewLevel]),
                        stat_musuh(Pokemon, NewLevel),
                        sleep(1),
                        pilih_aksi_pokemon(Pokemon, NewLevel)
                    ;   write('Tidak ada Pokemon di sini.'), nl)
                ; write('Tidak bisa melewati tile tersebut.'), nl, show_map
            )
        ; write('Di luar batas peta!'), nl, show_map
    ).

/* === PILIH AKSI === */
pilih_aksi_pokemon(Pokemon, Level) :-
    nl,
    show_party,
    tampilkan_status_musuh(Pokemon, Level),
    write('Apa yang ingin kamu lakukan?'), nl,
    write('1. Bertarung'), nl,
    write('2. Menangkap'), nl,
    write('3. Kabur'), nl,
    write('Masukkan pilihan (1/2/3): '),
    catch(read(Pilihan), _, Pilihan = -1), 

    (
        Pilihan = 1 -> 
            fight
    ;   Pilihan = 2 ->
            tangkap_pokemon
    ;   Pilihan = 3 ->
            aksi_kabur
    ;   Pilihan = show_party ->
            show_party,
            posisi_pemain(_Nama, X, Y),
            pokemon_bersembunyi(X, Y, level_pokemon(PokemonBaru, LevelBaru)),
            pilih_aksi_pokemon(PokemonBaru, LevelBaru)
    ; 
        write('Pilihan tidak valid. Silakan coba lagi.'), nl,
        pilih_aksi_pokemon(Pokemon, Level)
    ).

/* === FIGHT === */
fight :-
    posisi_pemain(_, Px, Py),
    pokemon_bersembunyi(Px, Py, level_pokemon(PokemonDitemukan, LevelDitemukan)),
    level_count(BonusLevel),
    LevelAkhir is LevelDitemukan + BonusLevel,
    format('Memulai pertarungan dengan ~w level ~w~n', [PokemonDitemukan, LevelAkhir]),
    set_status_awal(PokemonDitemukan, LevelAkhir, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull),
    retractall(enemy_pokemon(_, _, _, _, _, _, _, _)),
    asserta(enemy_pokemon(PokemonDitemukan, LevelAkhir, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull)),
    retractall(in_battle(_)),
    asserta(in_battle(yes)),
    write('Pertarungan dimulai!'), nl,
    pilih_pokemon_utama,
    tampilkan_status_battle,
    aksi_battle.

/* === PILIH POKEMON === */
pilih_pokemon_utama :-
    pemain(Nama),
    write('Pilih Pokemon utama dari party:'), nl,
    findall((Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP),party(Nama, Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP),Daftar),
    ( Daftar = [] ->
        write('Tidak ada Pokemon di party!'), nl, fail
    ; tampilkan_party(Daftar, 1),
      write('Masukkan nomor pilihan: '), read(Idx),
      (nth1(Idx, Daftar, (Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)) ->
          retractall(party_pokemon(_, _, _, _, _, _, _, _, _)),
          asserta(party_pokemon(Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)),
          format('~w siap bertarung!~n', [Poke])
      ; (Idx = back ->
            pokemon_bersembunyi(_X1, _Y1, level_pokemon(Pokemon, Level)),
            pilih_aksi_pokemon(Pokemon, Level))
        ; write('Pilihan tidak valid.'), nl, pilih_pokemon_utama
      )
    ).

/* Menampilkan daftar Pokemon party */
tampilkan_party([], _).
tampilkan_party([(Poke, Lv, HP, HF, _, _, _, _)|T], N) :-
    format('~w. ~w (Lv ~w, HP ~w/~w)~n', [N, Poke, Lv, HP, HF]),
    N1 is N + 1,
    tampilkan_party(T, N1).

/* Menampilkan status pertarungan saat ini */
tampilkan_status_battle :-
    (party_pokemon(PokeP, LvP, HPnP, HPfP, _, _, _, _, _),
     enemy_pokemon(PokeE, LvE, HPnE, HPfE, _, _, _, _) ->
        write('--- Status Pertarungan ---'), nl,
        format('Pokemonmu: ~w (Lv ~w) - HP: ~w/~w~n', [PokeP, LvP, HPnP, HPfP]),
        format('Musuh    : ~w (Lv ~w) - HP: ~w/~w~n', [PokeE, LvE, HPnE, HPfE])
    ; write('Belum ada status pertarungan yang aktif.'), nl
    ).

/* Menghitung damage */
damage_party_to_enemy(SkillName, Damage) :-
    party_pokemon(PokeP, _, _, _, ATKnow, _, _, _, _),
    enemy_pokemon(PokeE, _, _, _, _, _, DEF, _),
    pokemon(PokeP, _, _TipeP, _, _, _, _, _, _, _),
    pokemon(PokeE, _, TipeE, _, _, _, _, _, _, _),
    skill(SkillName, TipeSkill, Power, _),
    modifier_tipe(TipeSkill, TipeE, Modifier),

    DEF > 0,
    Temp1 is Power * ATKnow,
    Temp2 is Temp1 / DEF,
    Temp3 is Temp2 * (1/5),
    Temp4 is Temp3 * Modifier,

    DamageFloat is Temp4 + 0.5,
    Damage is floor(DamageFloat).

/* === DAMAGE === */
damage_enemy_to_party(SkillName, Damage) :-
    enemy_pokemon(PokeE, _, _, _, ATKnow, _, _, _),
    party_pokemon(PokeP, _, _, _, _, _, DEF, _, _),
    pokemon(PokeE, _, _TipeE, _, _, _, _, _, _, _),
    pokemon(PokeP, _, TipeP, _, _, _, _, _, _, _),
    ( defending(yes) ->
        NEWDEF is DEF * 1.3
    ;
        NEWDEF is DEF
    ),
    ( skill(SkillName, TipeSkill, Power, _) ->
        true
    ;
        write('ERROR: Skill tidak ditemukan: '), write(SkillName), nl, fail
    ),

    ( modifier_tipe(TipeSkill, TipeP, Modifier) ->
        true
    ;
        write('ERROR: Modifier tidak ditemukan untuk tipe '),
        write(TipeSkill), write(' vs '), write(TipeP), nl, fail
    ),

    NEWDEF > 0, 
    Temp1 is Power * ATKnow,
    Temp2 is Temp1 / NEWDEF,
    Temp3 is Temp2 * (1/5),
    Temp4 is Temp3 * Modifier,
    DamageFloat is Temp4 + 0.5,
    Damage is floor(DamageFloat).


/* Fungsi utama aksi pemain saat battle */
aksi_battle :-
    in_battle(yes),
    party_pokemon(_, _, HPnP, _, _, _, _, _, _),
    HPnP > 0, 
    handle_turn_start_effects(player), 
    !,
    party_pokemon(_,_,NewHP,_,_,_,_,_,_),
    ( NewHP > 0 -> 
    nl,
    write('--- Giliranmu ---'), nl,
    write('1. Attack'), nl,
    write('2. Defend'), nl,
    write('3. Kabur'), nl,
    write('Masukkan pilihan (1/2/3): '),
    catch(read(Pilihan), _, Pilihan = -1),
    (
        Pilihan = 1 -> aksi_attack;
        Pilihan = 2 -> aksi_defend;
        Pilihan = 3 -> aksi_kabur;
        write('Pilihan tidak valid. Coba lagi.'), nl, aksi_battle
    )
 ).

/* === SKILL AKTIF === */
skill_aktif(NamaPokemon, Level, [Skill1]) :-
    pokemon(NamaPokemon, _, _, _, _, _, Skill1, _, _, _EvolLevel),
    Level < 5.

skill_aktif(NamaPokemon, Level, [Skill1, Skill2]) :-
    pokemon(NamaPokemon, _, _, _, _, _, Skill1, Skill2, _, _EvolLevel),
    Level >= 5.

apply_skill_effect(Target, lower_atk(Value)) :-
    (   Target == enemy -> % Jika targetnya adalah musuh
        % Ambil data musuh saat ini
        enemy_pokemon(PokeE, LvE, HPnE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
        % Hitung ATK baru, pastikan tidak kurang dari 1
        NewATK is max(1, ATKnE - Value),
        % Hapus fakta lama dan simpan fakta baru dengan ATK yang sudah dikurangi
        retractall(enemy_pokemon(_,_,_,_,_,_,_,_)),
        asserta(enemy_pokemon(PokeE, LvE, HPnE, HPfE, NewATK, ATKfE, DEFnE, DEFfE)),
        format('~w terkena efek! ATK turun sebesar ~w.~n', [PokeE, Value])
    ;   Target == player -> % Jika targetnya adalah pokemon pemain
        % Ambil data pokemon pemain saat ini
        party_pokemon(PokeP, LvP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP),
        % Hitung ATK baru, pastikan tidak kurang dari 1
        NewATK is max(1, ATKnP - Value),
        % Hapus fakta lama dan simpan fakta baru dengan ATK yang sudah dikurangi
        retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
        asserta(party_pokemon(PokeP, LvP, HPnP, HPfP, NewATK, ATKfP, DEFnP, DEFfP, EXP)),
        format('~w terkena efek! ATK turun sebesar ~w.~n', [PokeP, Value])
    ).

apply_skill_effect(player, heal_40_percent) :-
    party_pokemon(PokeP, LvP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP),
    HealAmount is round(HPfP * 0.4),
    NewHP is min(HPfP, HPnP + HealAmount),
    retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
    asserta(party_pokemon(PokeP, LvP, NewHP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),
    format('~w menggunakan Rest dan memulihkan HP sebesar ~w!~n', [PokeP, HealAmount]).

apply_skill_effect(Target, paralyze_20) :-
    retractall(status_paralyze(Target)), % Hapus status paralyze lama jika ada
    asserta(status_paralyze(Target)),
    format('~w sekarang berisiko gagal menyerang!~n', [Target]).

apply_skill_effect(Target, burn(Damage, Duration)) :-
    retractall(status_burn(Target, _, _)), % Hapus status burn lama jika ada
    asserta(status_burn(Target, Damage, Duration)),
    format('~w sekarang terbakar (burn)!~n', [Target]).

handle_turn_start_effects(WhoseTurn) :-
    (   status_burn(WhoseTurn, Damage, Duration) ->
        (   WhoseTurn == enemy ->
                enemy_pokemon(PokeE, LvE, HPnE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
                NewHP is max(0, HPnE - Damage),
                retractall(enemy_pokemon(_,_,_,_,_,_,_,_)),
                asserta(enemy_pokemon(PokeE, LvE, NewHP, HPfE, ATKnE, ATKfE, DEFnE, DEFfE)),
                format('~w terluka oleh burn! -~w HP~n', [PokeE, Damage])
            ;   WhoseTurn == player ->
                party_pokemon(PokeP, LvP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP),
                NewHP is max(0, HPnP - Damage),
                retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
                asserta(party_pokemon(PokeP, LvP, NewHP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),
                format('~w terluka oleh burn! -~w HP~n', [PokeP, Damage])
        ),
        NewDuration is Duration - 1,
        retract(status_burn(WhoseTurn, _, _)),
        (   NewDuration > 0 ->
            asserta(status_burn(WhoseTurn, Damage, NewDuration))
        ;   format('Efek burn pada ~w telah hilang.~n', [WhoseTurn])
        ),
        (   (WhoseTurn == enemy, NewHP =< 0) -> write('Musuh pingsan karena burn!'), nl, end_battle, ! ; true ),
        (   (WhoseTurn == player, NewHP =< 0) -> write('Pokemonmu pingsan karena burn!'), nl, ganti_pokemon_utama, !, fail ; true )
    ;
        true 
    ).


apply_skill_effect(_, none) :- !.

/* === ATTACK === */
aksi_attack :-
    write('Pilih jenis serangan:'), nl,
    party_pokemon(PokeP, LevelP, _, _, _ATKP, _, _, _, _),
    ( skill_aktif(PokeP, LevelP, [Skill1, Skill2]) ->
        write('0. Basic Attack'), nl,
        write('1. '), write(Skill1), nl,
        write('2. '), write(Skill2), nl,
        write('Masukkan pilihan: '),
        catch(read(N), _, N = -1),
        (
            N == 0 -> do_basic_attack ;
            N == 1 -> do_skill_attack(Skill1) ;
            N == 2 -> do_skill_attack(Skill2) ;
            write('Pilihan tidak valid.'), nl, aksi_attack
        )
    ; skill_aktif(PokeP, LevelP, [Skill1]) ->
        write('0. Basic Attack'), nl,
        write('1. '), write(Skill1), nl,
        write('Masukkan pilihan: '),
        catch(read(N), _, N = -1),
        (
            N == 0 -> do_basic_attack ;
            N == 1 -> do_skill_attack(Skill1) ;
            write('Pilihan tidak valid.'), nl, aksi_attack
        )
    ;  
        write('Tidak ada skill yang bisa digunakan.'), nl
    ).

do_basic_attack :-
    party_pokemon(PokeP, _, _, _, ATKP, _, _, _, _),
    enemy_pokemon(PokeE, LevelE, HPnE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
    Damage is max(1, round(ATKP - DEFnE / 2)),
    HPnE2 is max(0, HPnE - Damage),
    retractall(enemy_pokemon(_, _, _, _, _, _, _, _)),
    asserta(enemy_pokemon(PokeE, LevelE, HPnE2, HPfE, ATKnE, ATKfE, DEFnE, DEFfE)),
    format('~w menggunakan Basic Attack dan memberikan ~w damage!~n', [PokeP, Damage]),
    (HPnE2 =< 0 -> write('Pokemon musuh telah dikalahkan!~n'), end_battle ; giliran_musuh).

do_skill_attack(SkillName) :-
    (   SkillName == rest ->
        % --- LOGIKA KHUSUS UNTUK REST ---
        write('Pokemonmu menggunakan Rest!'), nl,
        apply_skill_effect(player, heal_40_percent), % Targetnya 'player'
        tampilkan_status_battle,
        nl,
        write('Giliran selesai, sekarang giliran musuh.'), nl,
        giliran_musuh
    ;
    party_pokemon(PokeP, LevelP, HPnP, HPfP, _, _, _, _, _),
    enemy_pokemon(PokeE, LevelE, HPnE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
    damage_party_to_enemy(SkillName, Damage),  
    HPtemp is HPnE - Damage,
    (HPtemp < 0 -> HPnE2 = 0 ; HPnE2 = HPtemp),

    retractall(enemy_pokemon(_, _, _, _, _, _, _, _)),
    asserta(enemy_pokemon(PokeE, LevelE, HPnE2, HPfE, ATKnE, ATKfE, DEFnE, DEFfE)),

    skill(SkillName, TipeSkill, _, Effect),
    pokemon(PokeP, _, _, _, _, _, _, _, _, _),
    pokemon(PokeE, _, TipeE, _, _, _, _, _, _, _),
    modifier_tipe(TipeSkill, TipeE, Modifier),

    format('~w menggunakan ~w (Tipe: ~w) terhadap ~w (Tipe: ~w)~n', [PokeP, SkillName, TipeSkill, PokeE, TipeE]),
    format('Efektivitas: ~w, Damage: ~w~n', [Modifier, Damage]),
    format('Pokemonmu: ~w (Lv ~w) - HP: ~w/~w~n', [PokeP, LevelP, HPnP, HPfP]),
    format('Musuh    : ~w (Lv ~w) - HP: ~w/~w~n', [PokeE, LevelE, HPnE2, HPfE]),

    apply_skill_effect(enemy, Effect),

    (HPnE2 =< 0 ->
        write('Pokemon musuh telah dikalahkan!'), nl,
        end_battle
    ;
        giliran_musuh)
    ).


/* Bertahan: mengaktifkan status defend */
aksi_defend :-
    retractall(defending(_)),
    asserta(defending(yes)),
    write('Pokemonmu bersiap bertahan. Serangan musuh akan berkurang 30% pada giliran ini.'), nl,
    giliran_musuh.

/* Kabur dari pertarungan */
aksi_kabur :-
    write('Kamu memutuskan untuk kabur...'), nl,
    retractall(in_battle(_)),
    write('Berhasil melarikan diri!'), nl.

giliran_musuh :-
    handle_turn_start_effects(enemy),
    !, 
    enemy_pokemon(_, _, HPnE, _, _, _, _, _), 
    (   HPnE > 0 -> 
        (   retract(status_paralyze(enemy)) -> 
            random(R), 
            (   R < 0.2 -> 
                format('Musuh gagal menyerang karena paralyze!~n'),
                tampilkan_status_battle,
                aksi_battle 
            ;
                musuh_menyerang 
            )
        ;
            musuh_menyerang 
        )
    ;
        true 
    ).

musuh_menyerang :-
    enemy_pokemon(PokeE, LvE, _, _, _, _, _, _),
    party_pokemon(PokeP, LvP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP),
    pokemon(PokeE, _, _, _, _, _, Skill1, Skill2,_, _),

    (   LvE < 5 ->
        random(0, 4, R),
        ( R = 0 -> SkillName = normal ; SkillName = Skill1 )
    ;   random(0, 4, R),
        ( R = 0 -> SkillName = normal ;
          R = 1 -> SkillName = Skill1 ;
          R = 2 -> SkillName = Skill1 ;
                  SkillName = Skill2 )
    ),

    damage_enemy_to_party(SkillName, Damage),
    HPnP2Temp is HPnP - Damage,
    ( HPnP2Temp < 0 -> HPnP2 = 0 ; HPnP2 = HPnP2Temp ),

    retractall(party_pokemon(_, _, _, _, _, _, _, _, _)),
    asserta(party_pokemon(PokeP, LvP, HPnP2, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),

    format('Musuh menggunakan ~w dan menyerang ~w sebesar ~w damage!', [SkillName, PokeP, Damage]),nl,

    skill(SkillName, _, _, Effect),
    apply_skill_effect(player, Effect),

    (   HPnP2 =< 0 ->
        write('Pokemonmu pingsan! Silakan pilih Pokemon lain.'), nl,
        pemain(Nama),
        retract(party(Nama, PokeP, _, _, _, _, _, _, _, _)),
        asserta(party(Nama, PokeP, LvP, HPnP2, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),
        ganti_pokemon_utama,
        tampilkan_status_battle,
        aksi_battle
    ;
        tampilkan_status_battle,
        aksi_battle
    ).


ganti_pokemon_utama :-
    pemain(Nama),
    findall((Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP), party(Nama, Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP), Daftar),
    nl,

    ( \+ (member((_, _, HPx, _, _, _, _, _, _), Daftar), HPx > 0) ->
        write('Semua Pokemonmu pingsan! Pertarungan berakhir.'), nl,
        end_game(lose)
    ;
        write('Pokemon utama kamu telah pingsan! Pilih penggantinya:'), nl,
        tampilkan_party_dengan_status(Daftar, 1),
        repeat,
            write('Masukkan nomor pilihan: '),
            read(Idx),
            nth1(Idx, Daftar, (Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)),
            ( HP > 0 ->
                retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
                asserta(party_pokemon(Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)),
                format('~w sekarang bertarung!~n', [Poke]),
                tampilkan_status_battle,
                !
            ;
                write('Pokemon tersebut pingsan! Pilih yang lain.'), nl,
                fail
            )
    ).

tampilkan_party_dengan_status([], _).
tampilkan_party_dengan_status([(Poke, Lv, HP, HF, _, _, _, _, _)|T], N) :-
    (
        HP =< 0 -> Status = '[Pingsan]' ;
        Status = ''
    ),
    format('~d. ~w (Lv ~d) - HP: ~d/~d ~w~n', [N, Poke, Lv, HP, HF, Status]),
    N1 is N + 1,
    tampilkan_party_dengan_status(T, N1).


end_battle :-
    pemain(Pemain),

    enemy_pokemon(PokeE, LevelE, _, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
    format('Apa yang akan kamu lakukan dengan Pokemon ~w (Level ~w) ini?~n', [PokeE, LevelE]),
    write('1. Masukkan ke Inventori'), nl,
    write('2. Buang'), nl,
    write('Pilihan Kamu (1/2) = '),
    read(Input),

    ( Input == 1 ->
        ( isi_tas(Pemain, Slot, item_pokeball(kosong)) ->
            retract(isi_tas(Pemain, Slot, item_pokeball(kosong))),
            asserta(isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(Pemain, PokeE, LevelE, HPfE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE, 0)))),
            format('Pokemon ~w Lv.~w dimasukkan ke pokeball slot ~w di tas.~n', [PokeE, LevelE, Slot])
        ;
            write('Tas penuh, tidak ada pokeball kosong untuk menyimpan Pokemon.'), nl,
            format('Pokemon ~w Lv.~w hilang karena tidak ada tempat di tas.~n', [PokeE, LevelE])
        )
    ; Input == 2 ->
        format('Pokemon ~w Lv.~w dibuang dan tidak masuk ke tas.~n', [PokeE, LevelE])
    ;
        write('Pilihan tidak valid, Pokemon dianggap dibuang.'), nl,
        format('Pokemon ~w Lv.~w hilang.~n', [PokeE, LevelE])
    ),

    party_pokemon(PokeP, LevelP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXPP),
    retractall(party(_, PokeP, _, _, _, _, _, _, _, _)),
    asserta(party(Pemain, PokeP, LevelP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXPP)),

    exp_didapat(PokeE, LevelE, EXPDidapat),
    forall(
        party(Pemain, Poke, Level, HPn, HPf, ATKn, ATKf, DEFn, DEFf, EXP),
        (
            tambah_exp([Poke, Level, HPf, ATKf, DEFf, EXP], EXPDidapat,
                       [NewPoke, NewLevel, NewHP, NewATK, NewDEF, NewEXP]),
            retract(party(Pemain, Poke, Level, HPn, HPf, ATKn, ATKf, DEFn, DEFf, EXP)),
            asserta(party(Pemain, NewPoke, NewLevel, HPn, NewHP, ATKn, NewATK, DEFn, NewDEF, NewEXP))
        )
    ),

    retractall(in_battle(_)),
    retractall(enemy_pokemon(_, _, _, _, _, _, _, _)),
    retractall(party_pokemon(_, _, _, _, _, _, _, _, _)),
    retractall(defending(_)),

    write('Pertarungan selesai. Pokemonmu telah disimpan dan siap bertarung kembali!'), nl.


/* ===CATCH=== */
catch_rate(Pokemon, Rate) :-
    pokemon(Pokemon, Rarity, _, _, _, _, _, _, _, _),
    rarity_catch_rate(Rarity, BaseRate),
    acak_0_35(Rand),
    Rate is BaseRate + Rand.

acak_0_35(Rand) :-
    random(X),         
    Rand is floor(X * 36).

tangkap_pokemon :-
    pemain(Pemain),
    posisi_pemain(Pemain, X, Y),
    ( pokemon_bersembunyi(X, Y, level_pokemon(Pokemon, Level)) ->
        catch_rate(Pokemon, Rate),
        tangkap_pokemon(Pemain, Pokemon, Rate, Level)
    ;
        write('Tidak ada Pokemon untuk ditangkap di posisi ini.'), nl
    ).

tangkap_pokemon(Pemain, Pokemon, Rate, Level) :-
    jumlah_pokeball_kosong(Pemain, JumlahKosong),
    level_count(N),
    NEWLevel is Level + N,
    ( JumlahKosong > 0 ->
        write('Catch Rate: '), write(Rate), nl,
        ( Rate > 50 ->
            write('Pokemon berhasil ditangkap langsung!'), nl,
            retract(isi_tas(Pemain, Slot, item_pokeball(kosong))),
            set_status_awal(Pokemon, NEWLevel, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull),
            asserta(isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(Pemain, Pokemon, NEWLevel, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull, 0)))),
            retractall(pokemon_bersembunyi(_, _, level_pokemon(Pokemon, _))),
            true
        ; 
            write('Catch rate rendah, kamu harus bertarung dulu dengan Pokemon ini!'), nl,
            fight
        )
    ;
        write('Tidak ada pokeball kosong di tas, tidak bisa menangkap Pokemon.'), nl,
        pilih_aksi_pokemon(Pokemon, NEWLevel)
    ).