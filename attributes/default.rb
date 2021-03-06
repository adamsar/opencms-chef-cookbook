default['opencms']['url'] = "http://www.opencms.jp/modules/files/opencms_8.5.2ja.zip"
default['opencms']['base_dir'] = "/ROOT/WEB-INF"
default['opencms']['hostname'] = node.has_key?("ec2")?node['ec2']['public_hostname']:node['hostname']
default['opencms']['database'] = 'opencms'
default['opencms']['standard_mode'] = "0644"

default['opencms']['modules'] = [
                                 "org.opencms.workplace_8.5.2",
                                 "org.opencms.workplace.categories_8.5.0",
                                 "org.opencms.workplace.handler_8.5.2",
                                 "org.opencms.workplace.administration_8.5.2",
                                 "org.opencms.workplace.explorer_8.5.2",
                                 "org.opencms.workplace.galleries_8.5.0",
                                 "org.opencms.workplace.help_8.5.0",
                                 "org.opencms.workplace.help.de_8.5.0",
                                 "org.opencms.workplace.help.en_8.5.0",
                                 "org.opencms.workplace.tools.accounts_8.5.2",
                                 "org.opencms.workplace.tools.cache_8.5.0",
                                 "org.opencms.workplace.tools.content_8.5.1",
                                 "org.opencms.workplace.tools.database_8.5.0",
                                 "org.opencms.workplace.tools.galleryoverview_8.5.0",
                                 "org.opencms.workplace.tools.history_8.5.0",
                                 "org.opencms.workplace.tools.link_8.5.0",
                                 "org.opencms.workplace.tools.modules_8.5.0",
                                 "org.opencms.workplace.tools.projects_8.5.2",
                                 "org.opencms.workplace.tools.publishqueue_8.5.0",
                                 "org.opencms.workplace.tools.scheduler_8.5.1",
                                 "org.opencms.workplace.tools.searchindex_8.5.1",
                                 "org.opencms.workplace.tools.workplace_8.5.2",
                                 "org.opencms.jquery_8.5.2",
                                 "org.opencms.editors_8.5.2",
                                 "org.opencms.editors.codemirror_8.5.2",
                                 "org.opencms.editors.editarea_8.5.0",
                                 "org.opencms.editors.fckeditor_8.5.1",
                                 "org.opencms.editors.tinymce_8.5.3",
                                 "org.opencms.languagedetection_8.5.2",
                                 "org.opencms.locale.de_8.5.2",
                                 "org.opencms.locale.es_8.5.0",
                                 "org.opencms.locale.it_8.5.0",
                                 "org.opencms.locale.ja_8.5.2",
                                 "org.opencms.locale.ru_8.5.0",
                                 "org.opencms.gwt_8.5.2",
                                 "org.opencms.ade.config_8.5.2",
                                 "org.opencms.ade.containerpage_8.5.2",
                                 "org.opencms.ade.contenteditor_8.5.2",
                                 "org.opencms.ade.editprovider_8.5.2",
                                 "org.opencms.ade.galleries_8.5.2",
                                 "org.opencms.ade.postupload_8.5.2",
                                 "org.opencms.ade.properties_8.5.2",
                                 "org.opencms.ade.publish_8.5.2",
                                 "org.opencms.ade.upload_8.5.2",
                                 "org.opencms.ade.sitemap_8.5.2"
                                ]
