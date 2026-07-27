// Trivial translation unit. Swift Build (Xcode's build system) expects a
// per-target merged object even when a target only supplies headers;
// without this file the link step fails looking for a nonexistent
// Cduckdb.o. The real DuckDB symbols come from the prebuilt
// Binaries/CduckdbBinary.xcframework archive, linked on the DuckDB target.
