#include <stdio.h>
#include <stdint.h>

void lfsr16(void)
{
	uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
	uint16_t lfsr = start_state;
	uint16_t bit;                    /* Must be 16bit to allow bit<<15 later in the code */
	unsigned period = 0;

	do {
		/* taps: 16 14 13 11; feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1 */
		bit  = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
		lfsr =  (lfsr >> 1) | (bit << 15);
		++period;
	} while (lfsr != start_state);

	printf("period16: %u\n", period);
}

void lfsr8(void)
{
	uint8_t start_state = 0xFA;
	uint8_t lfsr = start_state;
	uint8_t bit;

	unsigned period = 0;

	do {
		bit = ((lfsr >> 0) ^ (lfsr >> 3)) & 1;
		lfsr = (lfsr >> 1) | (bit << 7);
		++period;
		//printf("lfsr8: %u\n", (unsigned)lfsr);
	} while (lfsr != start_state);

	printf("period8: %u\n", period);
}

void lfsr4(void)
{
	uint8_t start_state = 0x5;
	uint8_t lfsr = start_state;
	uint8_t bit;

	unsigned period = 0;

	do {
		bit = ((lfsr >> 0) ^ (lfsr >> 1)) & 1;
		lfsr = (lfsr >> 1) | (bit << 3);
		++period;
		printf("lfsr4: %X\n", (unsigned)lfsr);
	} while (lfsr != start_state);

	printf("period4: %u\n", period);
}

int main(void)
{
	lfsr16();
	lfsr8();
	lfsr4();
	return 0;
}

