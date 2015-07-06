# TODO
- SIP: sip binary leaks memory. Figure out how to disable ASAN for it, or add a
  shell wrapper that sets ASAN_OPTIONS=detect_leaks=0 in its environment.
