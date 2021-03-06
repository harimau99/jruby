#!/usr/bin/env ruby

# Copyright (c) 2016 Oracle and/or its affiliates. All rights reserved.
# This code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 1.0
# GNU General Public License version 2
# GNU Lesser General Public License version 2.1

require 'ostruct'
require 'yaml'
require 'erb'

options = YAML.load_file('tool/truffle/options.yml')

options = options.map do |constant, (name, type, default, description)|
  case type
    when 'boolean'
      type = 'boolean'
      type_cons = 'BooleanOptionDescription'
      default = default.to_s
      null_default = false
    when 'verbosity'
      type = 'Verbosity'
      type_cons = 'VerbosityOptionDescription'
      default = case default.to_s
                  when 'nil'
                    'Verbosity.NIL'
                  when 'true'
                    'Verbosity.TRUE'
                  when 'false'
                    'Verbosity.FALSE'
                end
      null_default = 'Verbosity.FALSE'
    when 'integer'
      type = 'int'
      type_cons = 'IntegerOptionDescription'
      default = default.to_s
      null_default = 0
    when 'string'
      type = 'String'
      type_cons = 'StringOptionDescription'
      default = default.nil? ? 'null' : "\"#{default.to_s}\""
      null_default = 'null'
    when 'byte-string'
      type = 'byte[]'
      type_cons = 'ByteStringOptionDescription'
      default = 'null'
      null_default = 'null'
    when 'string-array'
      type = 'String[]'
      type_cons = 'StringArrayOptionDescription'
      default = "new String[]{#{default.map(&:inspect).join(', ')}}"
      null_default = 'null'
    else
      raise type.to_s
  end

  OpenStruct.new(
      :constant => constant,
      :name => name,
      :type => type,
      :default => default,
      :reference_default => /[A-Z]/.match(default[0]),
      :null_default => null_default,
      :description => description,
      :type_cons => type_cons
  )
end

File.write('truffle/src/main/java/org/jruby/truffle/options/Options.java', ERB.new(<<JAVA).result)
/*
 * Copyright (c) 2016 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0
 * GNU General Public License version 2
 * GNU Lesser General Public License version 2.1
 */
package org.jruby.truffle.options;

// This file is automatically generated by options.yml with 'jt build options'

import com.oracle.truffle.api.CompilerDirectives.CompilationFinal;

import javax.annotation.Generated;

@Generated("tool/truffle/generate-options.rb")
public class Options {

    <% options.each do |o| %><% if o.type.end_with?('[]') %>@CompilationFinal(dimensions=1) <% end %>public final <%= o.type %> <%= o.constant %>;
    <% end %>
    Options(OptionsBuilder builder) {
    <% options.each do |o| %>    <%= o.constant %> = builder.getOrDefault(OptionsCatalog.<%= o.constant %><%= o.reference_default ? ', ' + o.default : '' %>);
    <% end %>}

}
JAVA

File.write('truffle/src/main/java/org/jruby/truffle/options/OptionsCatalog.java', ERB.new(<<JAVA).result)
/*
 * Copyright (c) 2016 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0
 * GNU General Public License version 2
 * GNU Lesser General Public License version 2.1
 */
package org.jruby.truffle.options;

// This file is automatically generated by options.yml with 'jt build options'

import javax.annotation.Generated;

@Generated("tool/truffle/generate-options.rb")
public class OptionsCatalog {

    <% options.each do |o| %>public static final OptionDescription <%= o.constant %> = new <%= o.type_cons %>("<%= o.name %>", "<%= o.description %>", <%= o.reference_default ? o.null_default : o.default %>);
    <% end %>
    public static OptionDescription fromName(String name) {
        switch (name) {
            <% options.each do |o| %>case "<%= o.name %>":
                return <%= o.constant %>;
            <% end %>default:
                return null;
        }
    }

}
JAVA
