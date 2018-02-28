redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
   		print("\n")
    	print("\n")
    	print("\27[1;33m     : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("botBOT-IDadmin")
    	redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botBOT-IDid",naji.id_)
		if naji.first_name_ then
			redis:set("botBOT-IDfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botBOT-IDlanme",naji.last_name_)
		end
		redis:set("botBOT-IDnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		if redis:get('botBOT-IDmaxgpmmbr') then
			if naji.member_count_ >= tonumber(redis:get('botBOT-IDmaxgpmmbr')) then
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDgoodlinks", i.link)
			else
				redis:srem("botBOT-IDwaitelinks", i.link)
				redis:sadd("botBOT-IDsavedlinks", i.link)
			end
		else
			redis:srem("botBOT-IDwaitelinks", i.link)
			redis:sadd("botBOT-IDgoodlinks", i.link)
		end
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if redis:get("botBOT-IDstart") then
			redis:del("botBOT-IDstart")
			tdcli_function ({
				ID = "GetChats",
				offset_order_ = 9223372036854775807,
				offset_chat_id_ = 0,
				limit_ = 10000},
			function (i,naji)
				local list = redis:smembers("botBOT-IDusers")
				for i, v in ipairs(list) do
					tdcli_function ({
						ID = "OpenChat",
						chat_id_ = v
					}, dl_cb, cmd)
				end
			end, nil)
		end
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("botBOT-IDmaxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if redis:get("botBOT-IDmaxgroups") and redis:scard("botBOT-IDsupergroups") >= tonumber(redis:get("botBOT-IDmaxgroups")) then 
			redis:set("botBOT-IDmaxjoin", true)
			redis:set("botBOT-IDoffjoin", true)
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("botBOT-IDmaxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذف لینک) (.*)$") then
					local matches = text:match("^حذف لینک (.*)$")
					if matches == "عضویت" then
						redis:del("botBOT-IDgoodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد.")
					elseif matches == "تایید" then
						redis:del("botBOT-IDwaitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید پاکسازی شد.")
					elseif matches == "ذخیره شده" then
						redis:del("botBOT-IDsavedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده پاکسازی شد.")
					end
				elseif text:match("^(حذف کلی لینک) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "عضویت" then
						local list = redis:smembers("botBOT-IDgoodlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت بطورکلی پاکسازی شد.")
						redis:del("botBOT-IDgoodlinks")
					elseif matches == "تایید" then
						local list = redis:smembers("botBOT-IDwaitelinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید بطورکلی پاکسازی شد.")
						redis:del("botBOT-IDwaitelinks")
					elseif matches == "ذخیره شده" then
						local list = redis:smembers("botBOT-IDsavedlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده بطورکلی پاکسازی شد.")
						redis:del("botBOT-IDsavedlinks")
					end
				elseif text:match("^(توقف) (.*)$") then
					local matches = text:match("^توقف (.*)$")
					if matches == "عضویت" then	
						redis:set("botBOT-IDmaxjoin", true)
						redis:set("botBOT-IDoffjoin", true)
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار متوقف شد.")
					elseif matches == "تایید لینک" then	
						redis:set("botBOT-IDmaxlink", true)
						redis:set("botBOT-IDofflink", true)
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک در های در انتظار متوقف شد.")
					elseif matches == "شناسایی لینک" then	
						redis:del("botBOT-IDlink")
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک متوقف شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:del("botBOT-IDsavecontacts")
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده متوقف شد.")
					end
				elseif text:match("^(شروع) (.*)$") then
					local matches = text:match("^شروع (.*)$")
					if matches == "عضویت" then	
						redis:del("botBOT-IDmaxjoin")
						redis:del("botBOT-IDoffjoin")
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار فعال شد.")
					elseif matches == "تایید لینک" then	
						redis:del("botBOT-IDmaxlink")
						redis:del("botBOT-IDofflink")
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک های در انتظار فعال شد.")
					elseif matches == "شناسایی لینک" then	
						redis:set("botBOT-IDlink", true)
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک فعال شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:set("botBOT-IDsavecontacts", true)
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده فعال شد.")
					end
				elseif text:match("^(حداکثر گروه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgroups', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>تعداد حداکثر سوپرگروه های رجای تنظیم شد به : </i><b> "..matches.." </b>")
				elseif text:match("^(حداقل اعضا) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('botBOT-IDmaxgpmmbr', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>عضویت در گروه های با حداقل</i><b> "..matches.." </b> عضو تنظیم شد.")
				elseif text:match("^(حذف حداکثر گروه)$") then
					redis:del('botBOT-IDmaxgroups')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز گروه نادیده گرفته شد.")
				elseif text:match("^(حذف حداقل اعضا)$") then
					redis:del('botBOT-IDmaxgpmmbr')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
				elseif text:match("^(افزودن مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر در حال حاضر مدیر است.</i>")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>مقام کاربر به مدیر ارتقا یافت</i>")
					end
				elseif text:match("^(افزودن مدیرکل) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "مقام کاربر به مدیریت کل ارتقا یافت .")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'درحال حاضر مدیر هستند.')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به مقام مدیرکل منصوب شد.")
					end
				elseif text:match("^(حذف مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botBOT-IDadmin', msg.sender_user_id_)
								redis:srem('botBOT-IDmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما دیگر مدیر نیستید.")
						end
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت خلع شد.")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مدیر نمی باشد.")
				elseif text:match("^(تازه سازی ربات)$") or text:match("^(0)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی ربات بروز شد.</i>")
					elseif text:match("^leftall") or text:match("^(*raja#)$") then 
					   function lkj(arg, data) 
						bot_id=data.id_ 
						local list = redis:smembers('botBOT-IDsupergroups')
						for k,v in pairs(list) do
						redis:srem('botBOT-IDsupergroups',v)
						print(v)
						tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = v,
							user_id_ = bot_id,
							status_ = {
							  ID = "ChatMemberStatusLeft"
							},
						  }, dl_cb, nil)
						end
				end
				tdcli_function({ID="GetMe",},lkj, nil)
				return send(msg.chat_id_, msg.id_, "الان از همه گروه ها خارج میشم")
				elseif text:match("ریپورت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^(لیست) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local naji
					if matches == "مخاطبین" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "botBOT-ID_contacts.txt"},
								caption_ = "مخاطبین رجای شماره BOT-ID"}
							}, dl_cb, nil)
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار" then
						local text = "<i>لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "مسدود" then
						naji = "botBOT-IDblockedusers"
					elseif matches == "شخصی" then
						naji = "botBOT-IDusers"
					elseif matches == "گروه" then
						naji = "botBOT-IDgroups"
					elseif matches == "سوپرگروه" then
						naji = "botBOT-IDsupergroups"
					elseif matches == "لینک" then
						naji = "botBOT-IDsavedlinks"
					elseif matches == "مدیر" then
						naji = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لیست "..tostring(matches).." های تبلیغ گر شماره BOT-ID"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وضعیت مشاهده) (.*)$") then
					local matches = text:match("^وضعیت مشاهده (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده شده ✔️✔️\n</i><code>(تیک دوم فعال)</code>")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده نشده ✔️\n</i><code>(بدون تیک دوم)</code>")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("افزودن با شماره (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب ثبت  شد </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم شد به :</i>\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست جواب های خودکار پاک شد.</i>")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار تبلیغ گر فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار تبلیغ گر غیر فعال شد.</i>")
					end
				elseif text:match("^(تازه سازی)$") or text:match("^(00)$")then
					local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>تازه‌سازی آمار رجای شماره </i><code> BOT-ID </code> با موفقیت انجام شد.")
				elseif text:match("^(امار)$") or text:match("^(s)$") or text:match("^(+)$") or text:match("^(😂)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "✅️" or "⛔️"
					local numadd = redis:get("botBOT-IDaddcontact") and "✅️" or "⛔️"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "شمارتون مال کدوم کشور هست😂😂"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "✅️" or "⛔️"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "⛔️" or "✅️"
					local offlink = redis:get("botBOT-IDofflink") and "⛔️" or "✅️"
					local gp = redis:get("botBOT-IDmaxgroups") or "500"
					local mmbrs = redis:get("botBOT-IDmaxgpmmbr") or "1245"
					local nlink = redis:get("botBOT-IDlink") and "✅️" or "⛔️"
					local contact = redis:get("botBOT-IDsavecontacts") and "✅️" or "⛔️"
					local fwd =  redis:get("botBOT-IDfwdtime") and "✅️" or "⛔️" 
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local sima = os.date("%A🔜 %d %B")
					local fname = redis:get("botBOT-IDfname")

					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text =   [[
⛓💱 <i>رجای شماره</i> BOT-ID🚥💱⛓
✍وضعیت و امار 🖥⚡️]] .. tostring(fname) .. [[⚡
]]..tostring(offjoin)..[[ شروع🔛توقف عضویت 
⚙⏰ <b>]] .. tostring(s)..[[</b> ثانیه تا عضویت مجدد
➿ <b>]] .. tostring(glinks)..[[</b> لینک در انتظار عضویت
]]..tostring(offlink)..[[  شروع🔛توقف تایید لینک 
🌀 <b>]] .. tostring(ss)..[[</b> ثانیه تا بررسی لینک عضویت
]]..tostring(nlink)..[[ شروع🔛توقف شناسایی لینک
⛓ <b>]] .. tostring(wlinks)..[[</b> لینک شناسایی کرده
]]..tostring(fwd)..[[ ارسال زمانی روشن🔛خاموش
]].. tostring(autoanswer) ..[[ پاسخگوی خودکار روشن🔛خاموش
]]..tostring(contact)..[[ شروع🔛توقف افزودن مخاطب
]].. tostring(numadd) .. [[ افزودن با شماره روشن🔛خاموش
]].. tostring(msgadd) ..[[  افزودن با پیام روشن🔛خاموش
پیام ربات👈موقع اد کردن شراکانت👇 
]] .. tostring(txtadd) ..[[ 
حداکثر گروه<i> ]]..tostring(gp)..[[</i> 
حداقل اعضا<i> ]]..tostring(mmbrs)..[[</i>
📖 <b>]] .. tostring(contacts)..[[</b> مخاطب ذخیره شده
📊 <b>]] .. tostring(links)..[[</b> لینک عضو و ذخیره کرده
خروچ از همه گروهها👇⛔️
*raja#
👤 <b>]] .. tostring(usrs) .. [[</b> چت خصوصی
🎎 <b>]] .. tostring(gps) .. [[</b> گروه عادی
⬅️🔘✍️ <b>]] .. tostring(sgps) .. [[</b> سوپرگروه🌈👭👬
<b>]] .. tostring(sima) .. [[</b>
 ]]
					return send(msg.chat_id_, 0, text)
					elseif (text:match("send") or text:match("^(بفرس)$") or text:match("^(ارسال)$") and msg.reply_to_message_id_ ~= 0) then
                          local list = redis:smembers("botBOT-IDsupergroups") 
                          local id = msg.reply_to_message_id_

                          local delay = redis:get("botBOT-IDdelay") or 0
                          local sgps = redis:scard("botBOT-IDsupergroups")
                          local esttime = ((tonumber(delay) * tonumber(sgps)) / 60) + 1
                          send(msg.chat_id_, msg.id_, "به " ..tostring(sgps).. "ارسال شد ")
                          for i, v in pairs(list) do
                            sleep(0)
                            tdcli_function({
                                  ID = "ForwardMessages",
                                  chat_id_ = v,
                                  from_chat_id_ = msg.chat_id_,
                                  message_ids_ = {[0] = id},
                                  disable_notification_ = 1,
                                  from_background_ = 1
                                  }, dl_cb, nil)
                            end
                            send(msg.chat_id_, msg.id_, "ربات شماره  BOT-ID")
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(خصوصی)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(گروه)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					if redis:get("botBOT-IDfwdtime") then
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
							if i % 4 == 0 then
								os.execute("sleep 3")
							end
						end
					else
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
						end
					end
						return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(ارسال زمانی) (.*)$") then
					local matches = text:match("^ارسال زمانی (.*)$")
					if matches == "روشن" then
						redis:set("botBOT-IDfwdtime", true)
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال فعال شد.</i>")
					elseif matches == "خاموش" then
						redis:del("botBOT-IDfwdtime")
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال غیر فعال شد.</i>")
					end
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)") 
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>" )
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر مسدود شد</i>")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>مسدودیت کاربر مورد نظر رفع شد.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت ثبت شد.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف شد.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$") 	
					send(msg.chat_id_, msg.id_, 'رجای از گروه مورد نظر خارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(افزودن به همه) (%d+)$") or text:match("^(برو) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمام گروه های من دعوت شد</i>")
					 elseif text:match("addallmybots") then
						local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
						local mybots = redis:smembers("botBOT-IDmybots")
                        local mybotscount = redis:scard("botBOT-IDmybots")
                                 for a, b in pairs(list) do
                                  for i, v in pairs(b) do 
                                      for t, y in ipairs(mybots) do
                                              tdcli_function ({
                                                    ID = "AddChatMember",
                                                    chat_id_ = v,
                                                    user_id_ = y,
                                                    forward_limit_ =  500
                                                    }, dl_cb, nil)
                                              end	
                                            end
                                          end
                                          return send (msg.chat_id_, msg.id_, "<code>همه " .. mybotscount .. " کاربر به تمام گروه های من دعوت شدند✔️</code>\n")
                                        elseif text:match("addmybot (%d+)") then
                                          local mybot = text:match("addmybot (%d+)")
                                          if not redis:sismember('botBOT-IDmybots', mybot) then
                                            redis:sadd('botBOT-IDmybots', mybot)
                                            return send (msg.chat_id_, msg.id_, "<code> ✅ ای دی به لیست اضافه شد </code>\n")
                                          else
                                            return send (msg.chat_id_, msg.id_, "<code>👌 ای دی تو لیست من هست</code>\n")
                                          end
                                        elseif text:match("delmybot (%d+)") then
                                          local mybot = text:match("delmybot (%d+)")
                                          if redis:sismember('botBOT-IDmybots', mybot) then
                                            redis:srem('botBOT-IDmybots', mybot)
                                            return send (msg.chat_id_, msg.id_, "<code>❌ ای دی از لیست حذف شد ❌</code>\n")
                                          else
                                            return send (msg.chat_id_, msg.id_, "<code>✔️ این ای دی تو لیست نبود ⁉️⁉️ </code>\n")
                                          end
                                        elseif text:match("list") or text:match("^(لیست)$") or text:match("^(22)$") then
                                          local mybots = redis:smembers ("botBOT-IDmybots") 
                                          local tt = "اد لیست گروهی ربات \n  \n 🔲 addallmybots \n  🔳 اد شدن ای دی های زیر به سوپر گروههای ربات  \n 🔲 addmybot 🆔(ID) \n 🔳 اضافه کردن ای دی به این لیست \n 🔲 delmybot 🆔(ID) \n 🔳 حذف ای دی از این لیست \n \n 🅰➿➿➿➿➿ \n 349469421 \n 🅰➿➿➿➿➿"
                                          for i, v in pairs(mybots) do
                           tt = tt .. "\n" .. v .. "\n"
                          tt = tt .. "🅰➿➿➿➿➿\n"
                     end
                 return send (msg.chat_id_, msg.id_, "<code>"..tt.."</code>\n")
				elseif (text:match("^(انلاین)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(راهنما)$") or text:match("^(2)$") then
									local txt =[[
راهنمای دستورات رجا
1 👈 انلاین
اعلام وضعیت رجا ✔️
❤️ حتی اگر رجا شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️
2 👈 افزودن مدیر شناسه
افزودن مدیر جدید با شناسه عددی داده شده 🛂
 3 👈 افزودن مدیرکل شناسه
افزودن مدیرکل جدید با شناسه عددی داده شده 🛂
 (⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)
 4 👈 حذف مدیر شناسه
حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️
5 👈 ترک گروه
خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃
6 👈 افزودن همه مخاطبین
افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕
6 👈 شناسه من
دریافت شناسه خود 🆔
7 👈 بگو متن
دریافت متن 🗣
8 👈 ارسال کن "شناسه" متن
ارسال متن به شناسه گروه یا کاربر داده شده 📤
9 👈 تنظیم نام "نام" فامیل
تنظیم نام ربات ✏️
10 👈 تازه سازی ربات
تازه‌سازی اطلاعات فردی ربات🎈
(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی رجا📍)
11 👈 تنظیم نام کاربری اسم
جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄
12 👈 حذف نام کاربری
حذف کردن نام کاربری ❎
13 👈 توقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب
غیر‌فعال کردن فرایند خواسته شده ◼️
14 👈 شروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب
فعال‌سازی فرایند خواسته شده ◻️
15 👈 حداکثر گروه عدد
تنظیم حداکثر سوپرگروه‌هایی که رجا عضو می‌شود،با عدد دلخواه ⬆️
16 👈 حداقل اعضا عدد
تنظیم شرط حدقلی اعضای گروه برای عضویت,با عدد دلخواه ⬇️
17 👈 حذف حداکثر گروه
نادیده گرفتن حدمجاز تعداد گروه ➰
18 👈 حذف حداقل اعضا
نادیده گرفتن شرط حداقل اعضای گروه ⚜
19 👈 ارسال زمانی روشن|خاموش
زمان بندی در فروارد و استفاده در دستور ارسال ⏲
🕐 بعد از فعال‌سازی ,ارسال به 400 مورد حدودا 4 دقیقه زمان می‌برد و  رجا طی این زمان پاسخگو نخواهد بود 🕐
20 👈 افزودن با شماره روشن|خاموش
تغییر وضعیت اشتراک شماره رجا در جواب شماره به اشتراک گذاشته شده 🔖
21 👈 افزودن با پیام روشن|خاموش
تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️
22 👈 تنظیم پیام افزودن مخاطب متن
تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨
23 👈 لیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر
دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄
24 👈 مسدودیت شناسه
مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫
25 👈 رفع مسدودیت شناسه
رفع مسدودیت کاربر با شناسه داده شده 💢
26 👈 وضعیت مشاهده روشن|خاموش 👁
تغییر وضعیت مشاهده پیام‌ها توسط رجا (فعال و غیر‌فعال‌کردن تیک دوم)
27 👈 امار
دریافت آمار و وضعیت رجا 📊
28 👈 تازه سازی
تازه‌سازی آمار رجا🚀
🎃مورد استفاده حداکثر یک بار در روز🎃
29 👈 ارسال به همه|خصوصی|گروه|سوپرگروه
ارسال پیام جواب داده شده به مورد خواسته شده 📩
(😄توصیه ما عدم استفاده از همه و خصوصی😄)
30 👈 ارسال به سوپرگروه متن
ارسال متن داده شده به همه سوپرگروه ها ✉️
(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)
31 👈 تنظیم جواب "متن" جواب
تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝
حذف جواب متن
حذف جواب مربوط به متن ✖️
32 👈 پاسخگوی خودکار روشن|خاموش
تغییر وضعیت پاسخگویی خودکار رجا به متن های تنظیم شده 📯
33 👈 حذف لینک عضویت|تایید|ذخیره شده
حذف لیست لینک‌های مورد نظر ❌
34 👈 حذف کلی لینک عضویت|تایید|ذخیره شده
حذف کلی لیست لینک‌های مورد نظر 💢
🔺پذیرفتن مجدد لینک در صورت حذف کلی🔻
35 👈 افزودن به همه شناسه
افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ➕➕
36 👈 ترک کردن شناسه
عملیات ترک کردن با استفاده از شناسه گروه 🏃
37 👈 خروچ از همه گروهها👇⛔️
*raja# یا leftall
ربات از همه گروه ها خارج میشود
راهنما
دریافت همین پیام 🆘 ]]
				return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(افزودن همه مخاطبین)$") or text:match("^(اد کن)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال افزودن مخاطبین به گروه ...</i>")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "شمارتون مال کدوم کشور هست😂😂"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	end
end