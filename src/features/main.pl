:- initialization(consult('fakta.pl')).
:- initialization(consult('rules.pl')).
:- initialization(consult('map.pl')).
:- initialization(consult('player.pl')).
:- initialization(consult('dynamic.pl')).

start_game :-
    retractall(posisi_pemain(_,_,_)),
    retractall(pokemon_bersembunyi(_,_,_)),
    retractall(isi_tas(_,_,_)),
    retractall(tile(_,_,_)),
    retractall(pemain(_)),
    retractall(party(_,_,_,_,_,_,_,_,_,_)),
    retractall(enemy_pokemon(_,_,_,_,_,_,_,_)),
    retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
    retractall(in_battle(_)),
    retractall(defending(_)),
    retractall(level_count(_)),
    retractall(status_burn(_,_,_)),
    retractall(status_paralyze(_)),
    write('Demo game telah diinisialisasi.'), nl,
    starter_game,
    init_map,
    peta_valid,
    acak_posisi_pemain,
    spawn_semua_pokemon,
    pemain(Nama),
    init_tas(Nama),
    init_moves,
    init_level,
    show_map.