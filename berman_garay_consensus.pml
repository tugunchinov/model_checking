#define N 4
#define K 1

#define M (N + K)

#define R (K + 1)

typedef Arraychan {
	chan ch[M] = [1] of {bit};
}

Arraychan A[M];

inline send_to_all(value, sender) {
	int j = 0;
	do
	:: j < M -> A[sender].ch[j]!value; j++;
	:: else -> break;
	od;
	
}

inline receive_all(messages, receiver) {
	int j = 0;
	do
	:: j < M -> A[j].ch[receiver]?messages[j]; j++;
	:: else -> break;
	od;
}

inline find_majority(messages, V, C) {
	int ones = 0;
	int zeroes = 0;
	int j = 0;

	do
	:: j < M ->
		if
		:: messages[j] == 0 -> zeroes++;
		:: messages[j] == 1 -> ones++;
		fi;
		j++;
	:: else -> break;
	od;

	if
	:: ones > zeroes ->
		V = 1;
		C = ones;
	:: else ->
		V = 0;
		C = zeroes;
	fi;
}

// Process' initial value
bit I[M] = {1, 1, 1, 1, 1, 1};

// Process' consensus value
bit CON[M] = {0, 1, 0, 1, 0, 1};

proctype Process(byte i) {
	bit V = I[i];
	bit U;
	int C;

	bit messages[M];

	byte round = 0;
	do
	:: round < R ->
		send_to_all(V, i);
		
		receive_all(messages, i);
		find_majority(messages, V, C);

		if
		:: round == i -> send_to_all(V, round);
		:: else -> skip;
		fi;

		A[round].ch[i]?U;
		if
		:: 4 * C < 3 * M -> V = U;
		:: else -> skip;
		fi;

		round++;
	:: else -> break;
	od;

	CON[i] = V;
}

proctype FaultyProcess(byte i) {
	bit messages[M];
	bit X = 0;
    int C;

    bit U;

	byte round = 0;
	do
	:: round < R ->
		send_to_all(X, 0);

		receive_all(messages, i);
        find_majority(messages, X, C);

		if
		:: round == i -> send_to_all(0, round);
		:: else -> skip;
		fi;

		A[round].ch[i]?U;

		round++;
        X = 1 - X;
	:: else -> break;
	od;
}

init {
	byte i = 0;
	do
	:: i < K -> 
		run FaultyProcess(i); 
		i++;
	:: else -> break
	od;

	do
	:: i < M -> 
		run Process(i); 
		i++;
	:: else -> break
	od;
}

#define CONSENSUS_VALUES_ARE_EQUAL ( \
    CON[M - 4] == CON[M - 3] && \
    CON[M - 3] == CON[M - 2] && \
    CON[M - 2] == CON[M - 1] \
)

#define INITIAL_VALUES_ARE_EQUAL ( \
    I[M - 4] == I[M - 3] && \
    I[M - 3] == I[M - 2] && \
    I[M - 2] == I[M - 1] \
)

#define CONSENSUS_VALUES_EQUAL_TO_INITIAL_VALUE ( \
    CON[M - 4] == I[M - 4] && \
    CON[M - 3] == I[M - 4] && \
    CON[M - 2] == I[M - 4] && \
    CON[M - 1] == I[M - 4] \
)

ltl { <>CONSENSUS_VALUES_ARE_EQUAL };
ltl { INITIAL_VALUES_ARE_EQUAL -> <>[]CONSENSUS_VALUES_EQUAL_TO_INITIAL_VALUE };
