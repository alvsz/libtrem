blueprints = custom_target('blueprints',
  input: files(
    'notification.blp',
    'sysTray.blp',
    'notificationCenter.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)
