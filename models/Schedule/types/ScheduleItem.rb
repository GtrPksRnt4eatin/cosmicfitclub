module Scheduling
  
  module Types

  	SCHEDULE_ITEM_TYPE = {
  	  :type      => String
  	  :starttime => Time,
  	  :endtime   => Time,
  	  :thumb_url => String,
  	  :title     => String  	  
  	}

    class ScheduleItem
      attr_accessor :type, :starttime, :endtime

      def day
      	Date.strptime(@starttime.iso8601).to_s
      end
      
      def ScheduleItem::from_occurrence(occ)
        { :type        => 'classoccurrence',
          :starttime   => occ.starttime,
          :endtime     => occ.endtime,
          :thumb_url   => occ.thumb_url,
          :title       => occ.classdef.name,

          :capacity    => {
          	:count => occ.headcount,
          	:limit => occ.capacity
          },
          
          :occurrence  => {
          	:id          => occ.id,
          	:classdef    => occ.classdef.to_token,    # ClassDef
          	:teacher     => occ.teacher.to_token,     # Staff
          	:instructors => 
          	:next_id     => occ.next_occurrence_id,
          	:prev_id     => occ.prev_occurrence_id
          }
        }
      end

      def ScheduleItem::from_class_schedule(hash)
      end

      def ScheduleItem::from_eventsession(sess)
        { :type      => 'eventsession',
          :starttime => Time.parse(sess.start_time),
          :endtime   => Time.parse(sess.end_time),
          :thumb_url => sess.event.thumb_url,
          :title     => sess.title,

          :capacity => {
          	:count => sess.headcount,
          	:limit => sess.capacity
          },

          :eventsession => {
          	:id           => sess.id,
          	:title        => sess.title,
          	:event        => sess.event.to_token,
          	:multisession => sess.event.multisession?
          }
        }
      end

      def ScheduleItem::from_rental(rental)
        { :type      => 'private',
          :starttime => Time.parse(rental.start_time.to_s),
          :endtime   => rental.end_time,
          :thumb_url => nil,
          :title     => rental.title
        }
      end

    end
  end
end