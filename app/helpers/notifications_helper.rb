module NotificationsHelper

    def send_notification_for_tags(resource)
        if Rails.application.config.jobs_execution
            TagsNotifierJob.perform_later resource
        end
    end

    def make_st_sector_notifications(notifiable)
        notifica = t("helpers.label.st_sector_notification.request")  + "<strong>" + notifiable.request + "</strong>"  + t("helpers.label.st_sector_notification.state") + "<strong>" + notifiable.state + "</strong>" +  t("helpers.label.st_sector_notification.note") + "<em>" + notifiable.note.truncate(100) + "</em>"
        notifica.html_safe
    end

    def make_st_sector_del_notifications(notifiable)
        notifica = t("helpers.label.st_sector_notification.request")  + "<strong>" + notifiable.request + " Associazione</strong>"  + t("helpers.label.st_sector_notification.state") + "<strong>" + notifiable.state + "</strong>" +  t("helpers.label.st_sector_notification.note") + "<em>" + notifiable.note.truncate(100) + "</em>"
        notifica.html_safe
    end

    def make_st_sector_mail_notifications(notifiable)
        notifica = "La tua richiesta di <strong>#{notifiable.request}</strong> dell'Associazione <strong>#{notifiable.name}</strong> è stata lavorata dal moderatore della piattaforma con il seguente esito: <strong>#{notifiable.state}</strong><br><br>Il moderatore ti segnala quanto segue: <em>#{notifiable.note}</em>"
        notifica.html_safe
    end

    def check_st_sector_deleted(notifiable)
        notifiable.class.name == "StSector" && StSector.states[notifiable.state] != 10 && StSector.states[StSector.where(sector_id: notifiable.sector_id).order("id desc").first.state] != 10
    end

    def check_st_sector_notification_delete(notifiable)
        notifiable.class.name == "StSector" && StSector.states[notifiable.state] == 10
    end

end
