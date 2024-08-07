#include "duckdb/common/progress_bar/display/terminal_progress_bar_display.hpp"
#include "duckdb/common/printer.hpp"
#include "duckdb/common/to_string.hpp"

namespace duckdb {

int32_t TerminalProgressBarDisplay::NormalizePercentage(double percentage) {
	if (percentage > 100) {
		return 100;
	}
	if (percentage < 0) {
		return 0;
	}
	return int32_t(percentage);
}

void TerminalProgressBarDisplay::PrintProgressInternal(int32_t percentage) {
	string result;
	// we divide the number of blocks by the percentage
	// 0%   = 0
	// 100% = PROGRESS_BAR_WIDTH
	// the percentage determines how many blocks we need to draw
	double blocks_to_draw = PROGRESS_BAR_WIDTH * (percentage / 100.0);
	// because of the power of unicode, we can also draw partial blocks

	// render the percentage with some padding to ensure everything stays nicely aligned
	result = "\r";
	if (percentage < 100) {
		result += " ";
	}
	if (percentage < 10) {
		result += " ";
	}
	result += to_string(percentage) + "%";
	result += " ";
	result += PROGRESS_START;
	idx_t i;
	for (i = 0; i < idx_t(blocks_to_draw); i++) {
		result += PROGRESS_BLOCK;
	}
	if (i < PROGRESS_BAR_WIDTH) {
		// print a partial block based on the percentage of the progress bar remaining
		idx_t index = idx_t((blocks_to_draw - static_cast<double>(idx_t(blocks_to_draw))) * PARTIAL_BLOCK_COUNT);
		if (index >= PARTIAL_BLOCK_COUNT) {
			index = PARTIAL_BLOCK_COUNT - 1;
		}
		result += PROGRESS_PARTIAL[index];
		i++;
	}
	for (; i < PROGRESS_BAR_WIDTH; i++) {
		result += PROGRESS_EMPTY;
	}
	result += PROGRESS_END;
	result += " ";

	Printer::RawPrint(OutputStream::STREAM_STDOUT, result);
}

void TerminalProgressBarDisplay::Update(double percentage) {
	auto percentage_int = NormalizePercentage(percentage);
	if (percentage_int == rendered_percentage) {
		return;
	}
	PrintProgressInternal(percentage_int);
	Printer::Flush(OutputStream::STREAM_STDOUT);
	rendered_percentage = percentage_int;
}

void TerminalProgressBarDisplay::Finish() {
	PrintProgressInternal(100);
	Printer::RawPrint(OutputStream::STREAM_STDOUT, "\n");
	Printer::Flush(OutputStream::STREAM_STDOUT);
}

} // namespace duckdb
