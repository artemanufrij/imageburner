icon_sizes = ['16','24','32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons/', meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )

    install_data(
        join_paths('icons/', meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons/hicolor', i + 'x' + i, 'mimetypes')
    )
endforeach

install_data(
    'icons/' + meson.project_name() + '.svg',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/scalable/apps')
)

install_data(
    meson.project_name() + '.contract',
    install_dir: join_paths(get_option('datadir'), 'contractor')
)

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)