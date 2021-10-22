class TagsNotifierJob < ActiveJob::Base 
    include JobLogsHelpers

    def perform(*resource)
        log_retryable_job(job_id, resource, self.class.to_s) { 
            getUserToNotify(resource)
        }
    end

    private

    def getUserToNotify(resource)
        usersToNotify = []
        usersToGet = []
        resource[0].tags.each do |tagToExplode|
            usersToGet << UserTag.where(tag_id: tagToExplode.id)
        end
        if usersToGet[0]
            usersToGet[0].each do |userToGet|
                usersToNotify << User.where(id: userToGet.user_id, pon_id: resource[0].pon_id)
            end
        end
        if usersToNotify.length > 0
            notify(resource[0], usersToNotify)
        end
    end

    def notify(resource, usersT) 
        usersT.each do |userToNotify|
            #logger.debug resource.title + ' - ' + resource.to_s
            if userToNotify.length != 0
                case resource
                when Asset
                    @notification = resource
                    @asset = Asset.with_hidden.find(resource.id)
                    if @notification.save
                        Notification.add(userToNotify[0], @asset)
                    end
                when BookingManager::ModerableBooking
                    @notification = resource
                    @moderable_booking = BookingManager::ModerableBooking.with_hidden.find(resource.id)
                    if @notification.save
                        Notification.add(userToNotify[0], @moderable_booking)
                    end                        
                when Event
                    @notification = resource
                    @event = Event.with_hidden.find(resource.id)
                    if @notification.save
                        Notification.add(userToNotify[0], @event)
                    end
                when Debate
                    @notification = resource
                    @debate = Debate.with_hidden.find(resource.id)
                    if @notification.save
                        Notification.add(userToNotify[0], @debate)
                    end
                when Proposal
                    @proposal = Proposal.with_hidden.find(resource.id)
                    if @proposal.save
                        Notification.add(userToNotify[0], @proposal)
                    end
                when Crowdfunding
                    @crowdfunding = Crowdfunding.with_hidden.find(resource.id)
                    if @crowdfunding.save
                        Notification.add(userToNotify[0], @crowdfunding)
                    end
                when Legislation::Process
                    @process = Legislation::Process.with_hidden.find(resource.id)
                    if @process.save
                        Notification.add(userToNotify[0], @process)
                    end
                end
            end
        end
    end
end